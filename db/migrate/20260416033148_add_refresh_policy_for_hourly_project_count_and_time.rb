# frozen_string_literal: true

class AddRefreshPolicyForHourlyProjectCountAndTime < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def up
    execute <<~SQL
      SELECT add_continuous_aggregate_policy('hourly_classification_count_and_time_per_project',start_offset => INTERVAL '5 days', end_offset => INTERVAL '30 minutes', schedule_interval => INTERVAL '1 h');
    SQL
  end

  def down
    execute <<~SQL
      SELECT remove_continuous_aggregate_policy('hourly_classification_count_and_time_per_project');
    SQL
  end
end
