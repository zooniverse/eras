# frozen_string_literal: true

class CreateDailyUserProjectClassificationCountAndTime < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.
  disable_ddl_transaction!
  def change
    execute <<~SQL
      create materialized view daily_user_classification_count_and_time_per_project
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1d', event_time) as day,
        user_id,
        project_id,
        count(*) as classification_count,
        sum(session_time) as total_session_time
      from classification_events where user_id IS NOT NULL
      group by day, user_id, project_id;
    SQL
  end
end
