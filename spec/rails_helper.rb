# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end
# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require 'database_cleaner'
require 'pundit/rspec'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# load rake tasks for use in test db schema setup
Eras::Application.load_tasks

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  config.fixture_path = "#{Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/6-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # For some reason, TimeScale hypertables and materialized views do not persist in test environment.
  # Therefore, before we run a test suite, we need to ensure that we have our hypertable and continuous aggregates created.
  config.before(:suite) do
    Rake::Task['db:create_classifications_hypertable'].invoke
    Rake::Task['db:create_comments_hypertable'].invoke
    Rake::Task['db:create_classification_user_groups_hypertable'].invoke
    Rake::Task['db:drop_continuous_aggregate_views'].invoke
    DatabaseCleaner.clean_with(:truncation)
    Rake::Task['db:create_continuous_aggregate_views'].invoke
  end
end
