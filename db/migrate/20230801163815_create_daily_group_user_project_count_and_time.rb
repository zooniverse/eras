# frozen_string_literal: true

class CreateDailyGroupUserProjectCountAndTime < ActiveRecord::Migration[7.0]
  # we have to disable the migration transaction because creating materialized views within it is not allowed.
  disable_ddl_transaction!
  ## We should note that this view looks very similar to the daily_user_classification_count_and_time_per_project (where the columns of that table are day, user_id, classification_count, total_session_time, project_id).
  ## The only difference between this view and daily_user_classification_count_and_time_per_project is that we are grouping by user_group_id (i.e. user_group_id is a column in this view).
  ## Even though the views are very similar we cannot query from just daily_user_classification_count_and_time_per_project to get stats info of that user for that group.
  ## Reason being:
  ## A) daily_user_classification_count_and_time_per_project does not consider WHEN a user has joined a group.
  ## (So if we queried for all time for the user group, the user's old classifications [when he/she/they were not part of the group] would be counted towards the user group) [Vice versa if a user LEAVES a user group]
  ## B) On the flip side, we cannot query from just daily_group_classification_count_and_time_per_user_per_prject when querying for just user stats, because not every user belongs to a group.
  def change
    execute <<~SQL
      create materialized view daily_group_classification_count_and_time_per_user_per_project
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1d', event_time) as day,
        user_group_id,
        user_id,
        project_id,
        count(*) as classification_count,
        sum(session_time) as total_session_time
      from classification_user_groups
      group by day, user_group_id, user_id, project_id;
    SQL
  end
end
