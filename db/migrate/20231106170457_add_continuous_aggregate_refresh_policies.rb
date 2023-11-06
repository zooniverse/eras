# frozen_string_literal: true

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
