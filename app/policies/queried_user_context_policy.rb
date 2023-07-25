# frozen_string_literal: true

class QueriedUserContextPolicy < ApplicationPolicy
  attr_reader :user

  def initialize(user, _record)
    super
    @user = user
  end

  def show?
    current_user_is_queried_user? || panoptes_admin?
  end

  def current_user_is_queried_user?
    user['id']&.to_i == user['queried_user_id']&.to_i
  end
end
