# rubocop:disable Layout/LineLength
# frozen_string_literal: true

require '../config/environment'
require 'net/http'
require 'uri'
require 'json'

# if project's classification_rate (difference in classifications / days apart) is higher than 5000 classifications per day and percentage difference is over 50% then we flag as potential project with spurious classifications
PROJECT_SPURIOUS_CLASSIFICATION_RATE_LOWER_BOUND = 5_000
PERCENTAGE_DIFF_THRESHOLD = 50

USER_CLASSIFICATION_RATE_LOWER_BOUND = 1
USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_ONE = 1_200
USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_TWO = 5_000
# 360 mins in seconds
USER_TOTAL_SESSION_TIME_LOWER_BOUND = 21_600

def normalize_hash_values(hash_of_arrays)
  hash_of_arrays.transform_values { |arr| arr.uniq.sort }
end

def format_report_for_slack(hash_of_arrays)
  hash_of_arrays.map { |k, v| "<https://www.zooniverse.org/lab/#{k}|Project #{k}>: #{v}" }.join("\n")
end

def projects_weekly_classifications_history
  puts 'Querying diffs to flag potential affected projects...'

  ActiveRecord::Base.connection.exec_query("SELECT record1.day as day1, record2.day as day_compare, record1.project_id, record2.project_id, record1.classification_count as day1_count, record2.classification_count as day_compare_count,abs(cast(record2.classification_count - record1.classification_count as float) / record1.classification_count) * 100 as percentage_diff, abs(cast(record2.classification_count - record1.classification_count as float) / extract(day from record2.day - record1.day)) as classification_rate
  FROM
      daily_classification_count_and_time_per_project AS record1
  INNER JOIN
      daily_classification_count_and_time_per_project AS record2 ON record1.project_id = record2.project_id
  WHERE
      record1.classification_count IS NOT NULL AND record2.classification_count IS NOT NULL and record1.day < record2.day and record1.day >= (CURRENT_DATE - INTERVAL '7 days') and record2.day >= CURRENT_DATE - INTERVAL '7 days' and record2.day < CURRENT_DATE and record1.classification_count > 1000 and record2.classification_count > 1000 order by classification_rate desc;")
end

def flagged_projects_to_high_classifying_dates
  projects_weekly_classifications_history.each_with_object(Hash.new { |h, k| h[k] = [] }) do |proj_history, projects_to_high_dates|
    next unless proj_history['classification_rate'] >= PROJECT_SPURIOUS_CLASSIFICATION_RATE_LOWER_BOUND && proj_history['percentage_diff'] >= PERCENTAGE_DIFF_THRESHOLD

    date =
      if proj_history['day1_count'] > proj_history['day_compare_count']
        proj_history['day1']
      elsif proj_history['day_compare_count'] > proj_history['day1_count']
        proj_history['day_compare']
      end

    projects_to_high_dates[proj_history['project_id']] << date.strftime('%Y-%m-%d') if date
  end.then { |flagged_projs_with_dates_hash| normalize_hash_values(flagged_projs_with_dates_hash) }
end

def user_rates_for_project(proj_id, dates)
  ActiveRecord::Base.connection.exec_query('SELECT *, cast(classification_count as float) / total_session_time as rate from daily_user_classification_count_and_time_per_project where project_id = $1 and day = ANY($2) order by classification_count desc', 'SQL', [proj_id, "{#{dates.join(',')}}"])
end

def flag_user_as_tier_one? (classification_count, rate)
  classification_count >= USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_ONE && classification_count <= USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_TWO && 
  rate > USER_CLASSIFICATION_RATE_LOWER_BOUND
end

def flag_user_in_duty_of_care_tier? (classification_count, rate, total_session_time)
  classification_count >= USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_ONE && classification_count <= USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_TWO && 
  rate <= USER_CLASSIFICATION_RATE_LOWER_BOUND && 
  total_session_time > USER_TOTAL_SESSION_TIME_LOWER_BOUND
end

def flagged_users(projects_to_high_classified_dates)
  tier_one = Hash.new { |h, k| h[k] = [] }
  tier_two = Hash.new { |h, k| h[k] = [] }
  duty_of_care_tier = Hash.new { |h, k| h[k] = [] }

  projects_to_high_classified_dates.each do |project_id, dates|
    user_rates_for_project(project_id, dates).each do |user_rate|
      classification_count = user_rate['classification_count']
      rate = user_rate['rate']
      total_session_time = user_rate['total_session_time']

      tier_one[project_id] << user_rate['user_id'] if flag_user_as_tier_one?(classification_count, rate)

      duty_of_care_tier[project_id] << user_rate['user_id'] if flag_user_in_duty_of_care_tier?(classification_count, rate, total_session_time)

      tier_two[project_id] << user_rate['user_id'] if classification_count >= USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_TWO
    end
  end

  [normalize_hash_values(tier_one), normalize_hash_values(tier_two), normalize_hash_values(duty_of_care_tier)]
end

def section(text)
  {
    type: 'section',
    text: {
      type: 'mrkdwn',
      text: text
    }
  }
end

def build_slack_message(projects, tier_one, duty_of_care_tier, tier_two)
  {
    blocks: [
      section("<@U0762C6KH> *Potential Spurious Classifications Report*"),
      { type: 'divider' },

      section("*High Classified Projects* \n"),
      section(format_report_for_slack(projects).presence || 'None'),

      section("*Flagged Users Tier I (> #{USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_ONE} classifications < #{USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_TWO} classifications in a day & rate > #{USER_CLASSIFICATION_RATE_LOWER_BOUND}/s)* \n"),
      section(format_report_for_slack(tier_one).presence || 'None'),

      section("*Duty of Care Tier  (> #{USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_ONE} classifications < #{USER_CLASSIFICATION_COUNT_THRESHOLD_TIER_TWO} classifications in a day & session_time > #{USER_TOTAL_SESSION_TIME_LOWER_BOUND/60} mins)* \n"),
      section(format_report_for_slack(duty_of_care_tier).presence || 'None'),

      section('*Flagged Users Tier II (> 5000 classifications/day)*'),
      section(format_report_for_slack(tier_two).presence || 'None')
    ]
  }
end

def post_to_slack(message)
  webhook_url = Rails.application.credentials.dig(:slack, :webhook_url)
  raise 'Missing Slack webhook URL' unless webhook_url

  uri = URI.parse(webhook_url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri)
  request['Content-Type'] = 'application/json'
  request.body = message.to_json
  response = http.request(request)

  if response.code.to_i == 200
    puts 'Slack message sent successfully'
  else
    puts "Slack API error: #{response.code} #{response.body}"
  end
end

puts 'Potential Affected Project IDs...'
flagged_projects = flagged_projects_to_high_classifying_dates

puts 'Finding Potential Spurious Classifiers for each Project...'
tier_one_users, tier_two_users, duty_of_care_tier_users = flagged_users(flagged_projects)

puts 'Sending to Slack...'
post_to_slack(
  build_slack_message(flagged_projects, tier_one_users, duty_of_care_tier_users, tier_two_users)
)
