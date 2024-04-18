# frozen_string_literal: true

require '../config/environment'
require './panoptes_membership_client'
require 'json'

corporate_user_groups_str = Rails.application.credentials.corporate_user_groups
corporate_partners = JSON.parse(corporate_user_groups_str)

puts 'Starting Classification and Membership Backfill...'

panoptes_client = PanoptesMembershipClient.new

corporate_partners.each do |corporate_partner|
  puts "Geting Ids of users that are not in group yet for #{corporate_partner['corp_name']}..."
  not_yet_member_user_ids = panoptes_client.user_ids_not_in_user_group(corporate_partner['user_group_id'], corporate_partner['domain_formats'])

  puts "Query found #{not_yet_member_user_ids.length} users not in the #{corporate_partner['corp_name']} user_group..."

  next unless not_yet_member_user_ids.length.positive?

  puts "Creating Memberships for #{corporate_partner['corp_name']}..."
  panoptes_client.insert_memberships(corporate_partner['user_group_id'], not_yet_member_user_ids)

  puts 'Querying Eras ClassificationEvents of newly created members...'
  classification_events_to_backfill = ClassificationEvent.where('user_id IN (?)', not_yet_member_user_ids)

  next unless classification_events_to_backfill.length.positive?

  puts 'Creating Classification User Groups...'
  classification_user_groups_to_create = []
  classification_events_to_backfill.each do |classification|
    classification_user_group = {
      classification_id: classification.classification_id,
      event_time: classification.event_time,
      project_id: classification.project_id,
      workflow_id: classification.workflow_id,
      user_id: classification.user_id,
      session_time: classification.session_time,
      user_group_id: corporate_partner['user_group_id']
    }
    classification_user_groups_to_create << classification_user_group
  end

  ClassificationUserGroup.upsert_all(classification_user_groups_to_create,
                                     unique_by: %i[classification_id event_time user_group_id user_id])

  puts 'ClassificationUserGroup Upsert Finished...'
end

today = Date.today.to_s
two_days_ago = (Date.today - 2).to_s
puts 'Classification and Membership Backfill Finished. Starting CA Refresh...'
puts 'Refreshing Continuous Aggregates dealing with User Groups...'

puts 'Refreshing Daily Group Classifications Count And Time...'
ActiveRecord::Base.connection.exec_query("CALL refresh_continuous_aggregate('daily_group_classification_count_and_time', '#{two_days_ago}', '#{today}')")

puts 'Refreshing Daily Group Classifications Count And Time Per Project...'
ActiveRecord::Base.connection.exec_query("CALL refresh_continuous_aggregate('daily_group_classification_count_and_time_per_project', '#{two_days_ago}', '#{today}')")

puts 'Refreshing Daily Group Classifications Count And Time Per User...'
ActiveRecord::Base.connection.exec_query("CALL refresh_continuous_aggregate('daily_group_classification_count_and_time_per_user', '#{two_days_ago}', '#{today}')")

puts 'Refreshing Daily Group Classifications Count And Time Per User And Project...'
ActiveRecord::Base.connection.exec_query("CALL refresh_continuous_aggregate('daily_group_classification_count_and_time_per_user_per_project', '#{two_days_ago}', '#{today}')")

puts 'Refreshing Daily Group Classifications Count And Time Per User And Workflow...'
ActiveRecord::Base.connection.exec_query("CALL refresh_continuous_aggregate('daily_group_classification_count_and_time_per_user_per_workflow', '#{two_days_ago}', '#{today}')")

puts 'Refreshing Daily Group Classifications Count And Time Per Workflow...'
ActiveRecord::Base.connection.exec_query("CALL refresh_continuous_aggregate('daily_group_classification_count_and_time_per_workflow', '#{two_days_ago}', '#{today}')")

puts 'Stats User Group Membership and Classification Backfill Completed'
