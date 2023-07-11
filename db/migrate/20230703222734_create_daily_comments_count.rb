# frozen_string_literal: true

class CreateDailyCommentsCount < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.
  disable_ddl_transaction!

  def change
    execute <<~SQL
      create materialized view daily_comment_count
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1d', event_time) as day,
        count(*) as comment_count
      from comment_events
      group by day;
    SQL
  end
end
