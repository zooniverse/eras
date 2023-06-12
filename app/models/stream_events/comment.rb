# frozen_string_literal: true

module StreamEvents
  class Comment
    def initialize(event)
      @data = event.fetch('data')
    end

    def process
      {
        comment_id: @data.fetch('id'),
        event_time: @data.fetch('created_at'),
        comment_updated_at: @data&.fetch('updated_at', nil),
        project_id: @data.fetch('project_id'),
        user_id: @data.fetch('user_id')
      }
    end
  end
end
