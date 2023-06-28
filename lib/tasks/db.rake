# frozen_string_literal: true

namespace :db do
  desc 'Create Classifications Hypertable'
  task create_classifications_hypertable: :environment do
    ActiveRecord::Base.connection.execute(
      "SELECT create_hypertable('classification_events', 'event_time', if_not_exists => TRUE);"
    )
  end

  desc 'Create Continuous Aggregates Views'
  task create_continuous_aggregate_views: :environment do
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_classification_count
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
            count(*) as classification_count
      FROM classification_events
      GROUP BY day;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_classification_count_per_workflow
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
      workflow_id,
            count(*) as classification_count
      FROM classification_events
      GROUP BY day, workflow_id;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_classification_count_per_project
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
      project_id,
            count(*) as classification_count
      FROM classification_events
      GROUP BY day, project_id;
    SQL
  end

  desc 'Drop Continuous Aggregates Views'
  task drop_continuous_aggregate_views: :environment do
    ActiveRecord::Base.connection.execute <<-SQL
    DROP MATERIALIZED VIEW IF EXISTS daily_classification_counts CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_classification_count_per_workflow CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_classification_count_per_project CASCADE;
    SQL
  end

  desc 'Setup development database'
  task 'setup:development': %w[db:create db:migrate]
end
