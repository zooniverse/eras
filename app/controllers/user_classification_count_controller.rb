# frozen_string_literal: true

class UserClassificationCountController < ApplicationController
  before_action :validate_params
  before_action :sanitize_params
  before_action :require_login

  def query
    current_user['queried_user_id'] = params[:id]
    authorize :queried_user_context, :show?
    user_classification_counts = CountUserClassifications.new(user_classification_count_params).call(user_classification_count_params)
    render json: UserClassificationCountsSerializer.new(user_classification_counts), serializer_options: serializer_opts_from_params
  end

  private

  def validate_params
    super
    raise ValidationError, 'Cannot query for project contributions and query by project/workflow' if params[:project_contributions] && (params[:workflow_id] || params[:project_id])
  end

  def sanitize_params
    params[:project_contributions] = params[:project_contributions].casecmp?('true') if params[:project_contributions]
    params[:time_spent] = params[:time_spent].casecmp?('true') if params[:time_spent]
  end

  def serializer_opts_from_params
    { period: params[:period],
      time_spent: params[:time_spent],
      project_contributions: params[:project_contributions] }
  end

  def user_classification_count_params
    params.permit(:id, :start_date, :end_date, :period, :workflow_id, :project_id, :project_contributions, :time_spent)
  end
end
