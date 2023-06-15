# frozen_string_literal: true

class ApplicationStatus
  def as_json(_options = {})
    {
      status: 'ok',
      revision: Rails.application.commit_id
    }
  end
end
