# frozen_string_literal: true

class QueriedUserGroupContextPolicy < ApplicationPolicy
  attr_reader :user

  def initialize(user, _record)
    super
    @user = user
  end

  def show?
    return true if panoptes_admin?

    if individual_stats_breakdown_requested?
      show_ind_stats_breakdown?
    else
      show_group_aggregate_stats?
    end
  end

  def show_group_aggregate_stats?
    # For types of group stats visibilities see: https://github.com/zooniverse/eras/wiki/(Panoptes)-User-Groups-Stats-Visibilities

    case group_stats_visibility
    when 'public_show_all', 'public_agg_show_ind_if_member', 'public_agg_only'
      true
    when 'private_show_agg_and_ind', 'private_agg_only'
      group_member?
    else
      false
    end
  end

  def show_ind_stats_breakdown?
    case group_stats_visibility
    when 'public_show_all'
      true
    when 'public_agg_show_ind_if_member', 'private_show_agg_and_ind'
      group_member?
    when 'public_agg_only', 'private_agg_only'
      group_admin?
    else
      false
    end
  end

  def group_member?
    current_user_membership && !current_user_roles.empty?
  end

  def group_admin?
    group_member? && current_user_roles.include?('group_admin')
  end

  def current_user_roles
    current_user_membership['roles']
  end

  def current_user_membership
    user['user_membership']
  end

  def individual_stats_breakdown_requested?
    user['individual_stats_breakdown'] || false
  end

  def group_stats_visibility
    user['user_group_stats_visibility']
  end
end
