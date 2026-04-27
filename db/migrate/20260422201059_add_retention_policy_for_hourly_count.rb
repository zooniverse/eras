class AddRetentionPolicyForHourlyCount < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def up
    execute <<~SQL
      SELECT add_retention_policy('hourly_classification_count', drop_after => INTERVAL '3 days');
    SQL
  end

  def down
    execute <<~SQL
      SELECT remove_retention_policy('hourly_classification_count');
    SQL
  end
end
