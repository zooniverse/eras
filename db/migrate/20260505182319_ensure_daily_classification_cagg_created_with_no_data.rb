class EnsureDailyClassificationCaggCreatedWithNoData < ActiveRecord::Migration[7.0]
  # Create continuous aggregate if it does not exist with no data to get production in sync with staging
  # without cagg backfilling in one go. We must backfill gradually in production due to disk space limitations and CPU usage limitations.
  def change
    execute <<~SQL
      DO $$
      BEGIN
        -- Only create if it doesn't already exist
        IF NOT EXISTS (
          SELECT 1
          FROM timescaledb_information.continuous_aggregates
          WHERE view_name = 'daily_classification_count_and_time_per_project'
        ) THEN

          CREATE MATERIALIZED VIEW daily_classification_count_and_time_per_project
          WITH (timescaledb.continuous,
            timescaledb.materialized_only = true
          ) AS
          SELECT
            time_bucket('1d', event_time) AS day,
            project_id,
            count(*) AS classification_count,
            sum(session_time) AS total_session_time
          FROM classification_events
          GROUP BY day, project_id
          WITH NO DATA;

        END IF;
      END $$;
    SQL
  end
end
