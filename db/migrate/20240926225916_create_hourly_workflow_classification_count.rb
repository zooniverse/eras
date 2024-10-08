class CreateHourlyWorkflowClassificationCount < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.

  # Due to how the front end pulls project stats (and workflow stats) all in one go, we hit performance issues; especially if a project has multiple workflows.
  # We have discovered that having a non-realtime/materialized only continous aggregate for our daily workflow count cagg is more performant than real time.
  # We plan to do the following:
  # - Update the daily_classification_count_per_workflow to be materialized only (i.e. non-realtime)
  # - Create a subsequent realtime cagg that buckets hourly that we will create data retention policies for. The plan is for up to 72 hours worth of hourly workflow classification counts of data.
  # - Update workflow query to first query the daily counts first and the query the hourly counts for just the specific date of now.
  disable_ddl_transaction!
  def change
    execute <<~SQL
      create materialized view hourly_classification_count_per_workflow
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1 hour', event_time) as hour,
        workflow_id,
        count(*) as classification_count
      from classification_events where event_time > now() - INTERVAL '5 days'
      group by hour, workflow_id;
    SQL
  end
end
