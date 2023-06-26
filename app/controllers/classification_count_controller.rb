# frozen_string_literal: true

class ClassificationCountController < ApplicationController
  before_action :validate_params
  def query
    skip_authorization
    classification_counts = CountClassifications.new(classification_count_params).call(classification_count_params)
    render json: ClassificationCountsSerializer.new(classification_counts), serializer_options: serializer_opts_from_params
  end

  private

  def serializer_opts_from_params
    { period: params[:period] }
  end

  def classification_count_params
    params.permit(:start_date, :end_date, :period, :workflow_id, :project_id)
  end
end
