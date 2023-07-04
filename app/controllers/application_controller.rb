# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pundit::Authorization
  class ValidationError < StandardError; end

  rescue_from ValidationError, with: :render_bad_request

  private

  def render_bad_request(exception)
    render_exception(400, exception)
  end

  def render_exception(status, exception)
    render status:, json: { error: exception.message }
  end

  def validate_params
    validate_date(params[:start_date]) if params[:start_date]
    validate_date(params[:end_date]) if params[:end_date]
    valid_date_range if params[:start_date] && params[:end_date]
    validate_period if params[:period]
    raise ValidationError, 'Cannot query by workflow and project. Either query by one or the other' if params[:workflow_id] && params[:project_id]
  end

  def validate_date(date_param)
    Date.parse(date_param)
  rescue ArgumentError
    raise ValidationError, 'Invalid date.'
  end

  def validate_period
    raise ValidationError, 'Invalid bucket option. Valid options for period is day, week, month, or year' unless Selectable::TIME_BUCKET_OPTIONS.keys.include? params[:period].downcase.to_sym
  end

  def valid_date_range
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    raise ValidationError, 'Date range entered is not valid' if start_date > end_date
  end
end
