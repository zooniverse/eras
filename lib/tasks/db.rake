# frozen_string_literal: true

namespace :db do
  desc 'Create Classifications Hypertable'
  task create_classifications_hypertable: :environment do
    ActiveRecord::Base.connection.execute(
      "SELECT create_hypertable('classification_events', 'event_time', if_not_exists => TRUE);"
    )
  end

  desc 'Create Comments Hypertable'
  task create_comments_hypertable: :environment do
    ActiveRecord::Base.connection.execute(
      "SELECT create_hypertable('comment_events', 'event_time', if_not_exists => TRUE);"
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

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_comment_count
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
            count(*) as comment_count
      FROM comment_events
      GROUP BY day;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_comment_count_per_project_and_user
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
            project_id,
            user_id,
            count(*) as comment_count
      FROM comment_events WHERE project_id IS NOT NULL
      GROUP BY day, project_id, user_id;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_comment_count_per_user
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
            user_id,
            count(*) as comment_count
      FROM comment_events
      GROUP BY day, user_id;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_user_classification_count_and_time_per_workflow
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
            user_id,
            workflow_id,
            count(*) as classification_count,
            sum(session_time) as total_session_time
      FROM classification_events WHERE user_id IS NOT NULL
      GROUP BY day, user_id, workflow_id;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_user_classification_count_and_time_per_project
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
            user_id,
            project_id,
            count(*) as classification_count,
            sum(session_time) as total_session_time
      FROM classification_events WHERE user_id IS NOT NULL
      GROUP BY day, user_id, project_id;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS daily_user_classification_count_and_time
      WITH (timescaledb.continuous) AS
      SELECT time_bucket('1 day', event_time) AS day,
            user_id,
            count(*) as classification_count,
            sum(session_time) as total_session_time
      FROM classification_events WHERE user_id IS NOT NULL
      GROUP BY day, user_id;
    SQL
  end

  desc 'Drop Continuous Aggregates Views'
  task drop_continuous_aggregate_views: :environment do
    ActiveRecord::Base.connection.execute <<-SQL
    DROP MATERIALIZED VIEW IF EXISTS daily_classification_counts CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_classification_count_per_workflow CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_classification_count_per_project CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_comment_count CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_comment_count_per_project_and_user CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_comment_count_per_user CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_user_classification_count_and_time_per_workflow CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_user_classification_count_and_time_per_project CASCADE;
    DROP MATERIALIZED VIEW IF EXISTS daily_user_classification_count_and_time CASCADE;
    SQL
  end

  desc 'Setup development database'
  task 'setup:development': %w[db:create db:schema:load db:create_classifications_hypertable db:create_comments_hypertable db:create_continuous_aggregate_views]
end
