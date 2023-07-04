class CreateDailyCommentCountPerUser < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.
  disable_ddl_transaction!
  def change
    execute <<~SQL
      create materialized view daily_comment_count_per_user
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1d', event_time) as day,
        user_id,
        count(*) as comment_count
      from comment_events where user_id IS NOT NULL
      group by day, user_id;
    SQL
  end
end
