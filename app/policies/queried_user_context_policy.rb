# frozen_string_literal: true

class QueriedUserContextPolicy < ApplicationPolicy
  attr_reader :user

  def initialize(user, record)
    super
    @user = user
    @record = record
  end

  def show?
    current_user_is_queried_user? || panoptes_admin?
  end

  def current_user_is_queried_user?
    user['id']&.to_i == record.queried_user_id&.to_i
  end
end
