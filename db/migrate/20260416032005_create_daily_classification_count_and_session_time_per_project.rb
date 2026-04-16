# frozen_string_literal: true

class CreateDailyClassificationCountAndSessionTimePerProject < ActiveRecord::Migration[7.0]
  # Meant to replace daily_classification_count_per_project.
  # original continuous aggregate (daily_classification_count_per_project) only accounted for sum of classification count per day.
  # there was an ask to keep track of project session time per day (i.e.  the total sesion time of all classifications of a project per day) as well.
  disable_ddl_transaction!
  def up
    execute <<~SQL
      create materialized view daily_classification_count_and_time_per_project
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1d', event_time) as day,
        project_id,
        count(*) as classification_count,
        sum(session_time) as total_session_time
      from classification_events
      group by day, project_id;
    SQL
  end

  def down
    execute <<~SQL
      DROP materialized view daily_classification_count_and_time_per_project;
    SQL
  end
end
