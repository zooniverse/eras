# frozen_string_literal: true

class UserClassificationCountController < ApplicationController
  before_action :validate_params
  before_action :sanitize_params
  # TODO: ensure if #top_project_contributions is given that we do not allow querying by both workflow_id and project_id
  # TODO validate top_project_contributions is an integer

  def query
    # TODO: policies and scopes should be added
    user_classification_counts = CountUserClassifications.new(user_classification_count_params).call(user_classification_count_params)
    render json: UserClassificationCountsSerializer.new(user_classification_counts), serializer_options: serializer_opts_from_params
  end

  private

  def sanitize_params
    params[:top_project_contributions] = params[:top_project_contributions].to_i if params[:top_project_contributions]
    params[:time_spent] = (params[:time_spent].downcase == 'true') if params[:time_spent]
  end

  def serializer_opts_from_params
    { period: params[:period],
      show_time_spent: params[:time_spent],
      top_project_contributions: params[:top_project_contributions] }
  end

  def user_classification_count_params
    params.permit(:id, :start_date, :end_date, :period, :workflow_id, :project_id, :top_project_contributions, :time_spent)
  end
end
