# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include Pundit::Authorization
  class ValidationError < StandardError; end
  class Unauthorized < StandardError; end

  attr_reader :current_user

  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  rescue_from ValidationError, with: :render_bad_request
  rescue_from Unauthorized, with: :not_authorized
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized
  rescue_from Panoptes::Client::ResourceNotFound, with: :not_found

  private

  def require_login
    @current_user = client.me
  rescue Panoptes::Client::ServerError
    raise Unauthorized, 'Could not check authentication with Panoptes'
  end

  def client
    return @client if @client

    authorization_header = request.headers['Authorization']
    raise Unauthorized, 'Missing Authorization header' unless authorization_header

    authorization_token = authorization_header.match(/\ABearer (.*)\Z/).try { |match| match[1] }
    raise Unauthorized, 'Missing Bearer token' unless authorization_token

    @client = Panoptes::Client.new \
      env: Rails.env.to_sym,
      auth: { token: authorization_token }
  end

  def panoptes_application_client
    @panoptes_application_client ||= Panoptes::Client.new \
      env: Rails.env.to_sym,
      auth: { client_id: Rails.application.credentials.panoptes_client_id,
              client_secret: Rails.application.credentials.panoptes_client_secret },
      params: { admin: true }
  end

  def not_authorized(exception)
    render_exception :forbidden, exception
  end

  def not_found(exception)
    render_exception :not_found, exception
  end

  def render_bad_request(exception)
    render_exception(400, exception)
  end

  def render_exception(status, exception)
    render status:, json: { error: exception.message }
  end

  def validate_params
    @start_date = validate_date(params[:start_date])
    @end_date = validate_date(params[:end_date])
    valid_date_range if @start_date && @end_date
    validate_period if params[:period]
    raise ValidationError, 'Cannot query by workflow and project. Either query by one or the other' if params[:workflow_id] && params[:project_id]
  end

  def validate_date(date_param)
    Date.parse(date_param) if date_param
  rescue ArgumentError
    raise ValidationError, 'Invalid date.'
  end

  def validate_period
    params[:period] = params[:period].downcase
    raise ValidationError, 'Invalid bucket option. Valid options for period is day, week, month, or year' unless SelectableWithTimeBucket::TIME_BUCKET_OPTIONS.keys.include? params[:period].to_sym
  end

  def valid_date_range
    raise ValidationError, 'Date range entered is not valid' if @start_date > @end_date
  end
end
