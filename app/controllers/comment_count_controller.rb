# frozen_string_literal: true

class CommentCountController < ApplicationController
  before_action :validate_params

  def query
    skip_authorization
    comment_counts = CountComments.new(comment_count_params).call(comment_count_params)
    render json: EventCountsSerializer.new(comment_counts), serializer_options: serializer_opts_from_params
  end

  private

  def serializer_opts_from_params
    { period: params[:period] }
  end

  def comment_count_params
    params.permit(:start_date, :end_date, :period, :project_id, :user_id)
  end
end
