# rubocop:disable Layout/LineLength
# frozen_string_literal: true

require '../config/environment'
require 'json'

# if project's classification_rate (difference in classifications / days apart) is higher than 5000 classifications per day and percentage difference is over 50% then we flag as potential project with spurious classifications
PROJECT_SPURIOUS_CLASSIFICATION_RATE_LOWER_BOUND = 5_000
PERCENTAGE_DIFF_THRESHOLD = 50

USER_CLASSIFICATION_RATE_LOWER_BOUND = 3
USER_CLASSIFICATION_COUNT_THRESHOLD = 1_000

puts 'Querying diffs to flag potential affected projects...'
projects_weekly_classifications_history = ActiveRecord::Base.connection.exec_query("SELECT record1.day as day1, record2.day as day_compare, record1.project_id, record2.project_id, record1.classification_count as day1_count, record2.classification_count as day_compare_count,abs(cast(record2.classification_count - record1.classification_count as float) / record1.classification_count) * 100 as percentage_diff, abs(cast(record2.classification_count - record1.classification_count as float) / extract(day from record2.day - record1.day)) as classification_rate
FROM
    daily_classification_count_per_project AS record1
INNER JOIN
    daily_classification_count_per_project AS record2 ON record1.project_id = record2.project_id
WHERE
    record1.classification_count IS NOT NULL AND record2.classification_count IS NOT NULL and record1.day < record2.day and record1.day >= (CURRENT_DATE - INTERVAL '7 days') and record2.day >= CURRENT_DATE - INTERVAL '2 days' and record2.day < CURRENT_DATE and record1.classification_count > 1000 and record2.classification_count > 1000 order by classification_rate desc;")

flagged_project_id_to_high_classifying_dates = Hash.new { |h, k| h[k] = [] }
projects_weekly_classifications_history.each do |proj_history|
  next unless proj_history['classification_rate'] >= PROJECT_SPURIOUS_CLASSIFICATION_RATE_LOWER_BOUND && proj_history['percentage_diff'] >= PERCENTAGE_DIFF_THRESHOLD

  if proj_history['day1_count'] > proj_history['day_compare_count']
    flagged_project_id_to_high_classifying_dates[proj_history['project_id']] << proj_history['day1'].strftime('%Y-%m-%d')
  elsif proj_history['day_compare_count'] > proj_history['day1_count']
    flagged_project_id_to_high_classifying_dates[proj_history['project_id']] << proj_history['day_compare'].strftime('%Y-%m-%d')
  end
end

puts 'Potential Affected Project IDs...'
puts flagged_project_id_to_high_classifying_dates

puts 'Finding Potential Spurious Classifiers for each Project...'

users_to_flag = []

flagged_project_id_to_high_classifying_dates.each do |proj_id, dates|
  user_rates_for_proj = ActiveRecord::Base.connection.exec_query('SELECT *, cast(classification_count as float) / total_session_time as rate from daily_user_classification_count_and_time_per_project where project_id = $1 and day = ANY($2) order by rate desc', 'SQL', [proj_id, "{#{dates.join(',')}}"])

  user_rates_for_proj.each do |user_rate|
    users_to_flag << user_rate['user_id'] if user_rate['classification_count'] >= USER_CLASSIFICATION_COUNT_THRESHOLD
  end
end

puts 'Flagged Users...'
puts users_to_flag
