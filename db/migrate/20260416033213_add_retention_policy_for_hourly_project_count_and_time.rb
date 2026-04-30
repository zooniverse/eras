# frozen_string_literal: true

class AddRetentionPolicyForHourlyProjectCountAndTime < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def up
    execute <<~SQL
      SELECT add_retention_policy('hourly_classification_count_and_time_per_project', drop_after => INTERVAL '3 days');
    SQL
  end

  def down
    execute <<~SQL
      SELECT remove_retention_policy('hourly_classification_count_and_time_per_project');
    SQL
  end
end
