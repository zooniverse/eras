# frozen_string_literal: true

# These refresh policies have a start_offset of 3 days, because that is the smallest possible starting offset (anything smaller will get a `refresh window is too small` db error)
# These refresh policies will look back at the associated tables (classification_events, comment_events, or classification_user_groups) for the past 3 days through the last hour of when the refresh job is run, and re-compute the continuous aggregate.

# These refresh policies run everyday, if we want to change the frequency refresh policies are run, we will need to update the `scheduling_interval` of the refresh policy

# Eg.
#
# Refresh Continuous Aggregate Job is run today Nov 6th 1:47PM CST, the job will look at the classification_events table for the past 3 days (Nov 3rd) through the past hour (Nov 6th 12:47 PM CST), and will check for any changes in the classification_events table that have NOT been calculated in previous refresh jobs and then update the caggs with updated calculations.

# More on refresh policies for continuous aggregates found here:
# https://docs.timescale.com/api/latest/continuous-aggregates/add_continuous_aggregate_policy/

class AddContinuousAggregateRefreshPolicies < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.
  disable_ddl_transaction!
  def change
    execute <<~SQL
      SELECT add_continuous_aggregate_policy('daily_classification_count', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 hour');

      SELECT add_continuous_aggregate_policy('daily_classification_count_per_project', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_classification_count_per_workflow', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_comment_count', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_comment_count_per_project_and_user', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_comment_count_per_user', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_group_classification_count_and_time', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_group_classification_count_and_time_per_project', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_group_classification_count_and_time_per_user', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_group_classification_count_and_time_per_user_per_project', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_group_classification_count_and_time_per_user_per_workflow', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_group_classification_count_and_time_per_workflow', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_user_classification_count_and_time', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_user_classification_count_and_time_per_project', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');

      SELECT add_continuous_aggregate_policy('daily_user_classification_count_and_time_per_workflow', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 day');
    SQL
  end
end
