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
    valid_date_range
    raise ValidationError, 'Cannot query by workflow and project. Either query by one or the other' if params[:workflow_id] && params[:project_id]
  end

  def valid_date_range
    start_date = Date.parse(params[:start_date]) if params[:start_date]
    end_date = Date.parse(params[:end_date]) if params[:end_date]
    return unless start_date && end_date
    raise ValidationError, 'Date range entered is not valid' if start_date > end_date
  end
end
