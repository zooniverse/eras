class CreateDailyGroupWorkflowClassificationCountAndTime < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.
  disable_ddl_transaction!
  def change
    execute <<~SQL
      create materialized view daily_group_classification_count_and_time_per_workflow
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1d', event_time) as day,
        user_group_id,
        workflow_id,
        count(*) as classification_count,
        sum(session_time) as total_session_time
      from classification_user_groups
      group by day, user_group_id, workflow_id;
    SQL
  end
end
