# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false
gem 'composite_primary_keys'
gem 'panoptes-client'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.6'
gem 'pundit'
gem 'rails', '~> 7.0', '>= 7.0.4.3'
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

group :production, :staging do
  gem 'newrelic_rpm'
  gem 'sentry-rails'
  gem 'sentry-ruby'
end

group :development, :test do
  gem 'database_cleaner'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'pry-byebug'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'simplecov', require: false
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  gem 'spring'
end
