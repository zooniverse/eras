# frozen_string_literal: true

class UserGroupClassificationCountController < ApplicationController
  before_action :validate_params
  before_action :sanitize_params
  before_action :require_login

  def query
    current_user['user_group_stats_visibility'] = queried_user_group['stats_visibility']
    current_user['individual_stats_breakdown'] = params[:individual_stats_breakdown]
    current_user['user_membership'] = current_user_membership
    authorize :queried_user_group_context, :show?
    if params[:individual_stats_breakdown]
      group_member_classification_counts = CountGroupMemberBreakdown.new.call(group_classification_count_params)

      render json: UserGroupMemberStatsBreakdownSerializer.new(group_member_classification_counts)
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

  def current_user_membership
    url = "/memberships?user_id=#{current_user['id']&.to_i}&user_group_id=#{params[:id]}"
    client.panoptes.get(url)['memberships'][0]
  end

  def queried_user_group
    url = "/user_groups/#{params[:id]}"
    panoptes_application_client.panoptes.get(url)['user_groups'][0]
  end

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
