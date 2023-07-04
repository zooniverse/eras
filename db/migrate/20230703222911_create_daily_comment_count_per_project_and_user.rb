class CreateDailyCommentCountPerProjectAndUser < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.
  disable_ddl_transaction!

  # NOTE: the way we structure Talk, every comment will always have a user_id since we force a contributor  to sign in before posting on Talk
  def change
    execute <<~SQL
      create materialized view daily_comment_count_per_project_and_user
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1d', event_time) as day,
        project_id,
        user_id,
        count(*) as comment_count
      from comment_events where project_id IS NOT NULL
      group by day, project_id, user_id;
    SQL
  end
end
