class CreateDataRetentionPolicyForHourlyWorkflowCount < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    execute <<~SQL
      SELECT add_retention_policy('hourly_classification_count_per_workflow', drop_after => INTERVAL '3 days');
    SQL
  end
end
