# frozen_string_literal: true

class CreateHourlyProjectClassificationCountAndTime < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.

  # Due to how the front end pulls project stats (and workflow stats) all in one go, we hit performance issues; especially if a project has multiple workflows.
  # We have discovered that having a non-realtime/materialized only continous aggregate for our daily project count cagg is more performant than real time.
  # We plan to do the following:
  # - Update the daily_classification_count_per_project to be materialized only (i.e. non-realtime)
  # - Create a subsequent realtime cagg that buckets hourly that we will create data retention policies for. The plan is for up to 72 hours worth of hourly project classification counts of data.
  # - Update project query to first query the daily counts first and then query the hourly counts for just the specific date of now.
  disable_ddl_transaction!
  def up
    execute <<~SQL
      create materialized view hourly_classification_count_and_time_per_project
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1 hour', event_time) as hour,
        project_id,
        count(*) as classification_count,
        sum(session_time) as total_session_time
      from classification_events where event_time > now() - INTERVAL '5 days'
      group by hour, project_id;
    SQL
  end

  def down
    execute <<~SQL
      DROP materialized view hourly_classification_count_and_time_per_project;
    SQL
  end
end
