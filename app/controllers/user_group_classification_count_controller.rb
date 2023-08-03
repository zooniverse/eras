# frozen_string_literal: true

class UserGroupClassificationCountController < ApplicationController
  before_action :validate_params
  before_action :sanitize_params
  #   before_action :require_login

  def query
    # TODO: Skipping Auth for now, Will introduce this in a separate PR
    # pundit policy for user groups, will probably look something like below:
    # current_user['queried_user_group_id'] = params[:id]
    # authorize :queried_user_group_context, :show?
    skip_authorization
    if params[:individual_stats_breakdown]
      # TODO: in a separate PR
      # Plan is to query from DailyGroupClassificationCountAndTimePerUserPerProject
    else
      group_classification_counts = CountGroupClassifications.new(group_classification_count_params).call(group_classification_count_params)
      group_active_user_classification_counts = CountGroupActiveUserClassifications.new(group_classification_count_params).call(group_classification_count_params)

      # We only calculate group project contributions as long as we are not querying by project_id or workflow_id
      project_contributions = CountGroupProjectContributions.new.call(group_classification_count_params) unless params[:project_id] || params[:workflow_id]
      render json: UserGroupClassificationCountsSerializer.new(group_classification_counts, group_active_user_classification_counts, project_contributions),
             serializer_options: serializer_opts_from_params

    end
  end

  private

  def validate_params
    super
    raise ValidationError, 'Cannot query individual stats breakdown with anything else EXCEPT start_date and end_date' if params[:individual_stats_breakdown] && non_date_range_params
  end

  def non_date_range_params
    params[:period] || params[:workflow_id] || params[:project_id] || params[:top_contributors]
  end

  def sanitize_params
    params[:individual_stats_breakdown] = params[:individual_stats_breakdown].casecmp?('true') if params[:individual_stats_breakdown]
    params[:top_contributors] = params[:top_contributors].to_i if params[:top_contributors]
  end

  def serializer_opts_from_params
    { period: params[:period],
      top_contributors: params[:top_contributors] }
  end

  def group_classification_count_params
    params.permit(:id, :start_date, :end_date, :period, :workflow_id, :project_id, :individual_stats_breakdown, :top_contributors)
  end
end
