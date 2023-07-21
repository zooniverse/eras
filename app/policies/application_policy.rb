# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
    raise Pundit::NotAuthorizedError, 'must be logged in to Panoptes' unless logged_in?
  end

  def logged_in?
    !!user
  end

  def panoptes_admin?
    user['admin'] == true
  end
end
