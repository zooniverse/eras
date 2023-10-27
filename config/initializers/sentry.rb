Sentry.init do |config|
    config.dsn = Rails.application.credentials.sentry_dsn
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.environment = Rails.env

    config.traces_sample_rate = 0.25
end