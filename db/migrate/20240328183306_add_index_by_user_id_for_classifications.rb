# frozen_string_literal: true

# Timescale currently does not support creating indexes concurrently. See: https://github.com/timescale/timescaledb/issues/504
# This means that we cannot avoid write locks.
# Timescale does offer adding indexes on a transaction per chunk basis.
# See: https://docs.timescale.com/api/latest/hypertable/create_index/ for more details.

class AddIndexByUserIdForClassifications < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    execute <<~SQL
      CREATE INDEX index_classification_events_on_user_id ON classification_events(user_id) WITH (timescaledb.transaction_per_chunk);
    SQL
  end
end
