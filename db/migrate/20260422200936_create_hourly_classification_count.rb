class CreateHourlyClassificationCount < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def up
    execute <<~SQL
      create materialized view hourly_classification_count
      with (
        timescaledb.continuous
      ) as
      select
        time_bucket('1 hour', event_time) as hour,
        count(*) as classification_count
      from classification_events where event_time > now() - INTERVAL '5 days'
      group by hour;
    SQL
  end

  def down
    execute <<~SQL
      DROP materialized view hourly_classification_count;
    SQL
  end
end
