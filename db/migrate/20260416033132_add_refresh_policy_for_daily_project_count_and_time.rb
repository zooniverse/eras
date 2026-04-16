# frozen_string_literal: true

class AddRefreshPolicyForDailyProjectCountAndTime < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def up
    execute <<~SQL
      SELECT add_continuous_aggregate_policy('daily_classification_count_and_time_per_project', start_offset => INTERVAL '3 days', end_offset => INTERVAL '1 hour',  schedule_interval => INTERVAL '1 hour');
    SQL
  end

  def down
    execute <<~SQL
      SELECT remove_continuous_aggregate_policy('daily_classification_count_and_time_per_project');
    SQL
  end
end
