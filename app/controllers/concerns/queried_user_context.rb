# frozen_string_literal: true

class QueriedUserContext
  attr_reader :queried_user_id

  def initialize(queried_user_id)
    @queried_user_id = queried_user_id
  end
end
