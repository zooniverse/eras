class CreateHourlyUserClassificationCountPerWorkflow < ActiveRecord::Migration[7.0]
    disable_ddl_transaction!
  def up
    execute <<~SQL
      create materialized view hourly_user_classification_count_and_time_per_workflow
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1 hour', event_time) as hour,
        user_id,
        workflow_id,
        count(*) as classification_count,
        sum(session_time) as total_session_time
      from classification_events where event_time > now() - INTERVAL '14 days'
      group by hour, user_id, workflow_id;
    SQL
  end

  def down
    execute <<~SQL
      DROP materialized view hourly_user_classification_count_and_time_per_workflow;
    SQL
  end
end
