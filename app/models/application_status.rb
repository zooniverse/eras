# frozen_string_literal: true

class ApplicationStatus
  def as_json(_options = {})
    {
      revision: Rails.application.commit_id
    }
  end
end
