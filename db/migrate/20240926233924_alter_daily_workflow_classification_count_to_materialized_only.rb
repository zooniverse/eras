class AlterDailyWorkflowClassificationCountToMaterializedOnly < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    execute <<~SQL
      ALTER MATERIALIZED VIEW daily_classification_count_per_workflow set (timescaledb.materialized_only = true);
    SQL
  end
end
