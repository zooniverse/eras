# frozen_string_literal: true

module StreamEvents
  class Classification
    def initialize(event)
      @data = event.fetch('data')
      @links = event.fetch('data').fetch('links')
    end

    def process
      {
        classification_id: @data.fetch('id'),
        event_time: @data.fetch('created_at'),
        classification_updated_at: @data.fetch('updated_at'),
        started_at: StreamEvents.started_at(@data),
        finished_at: StreamEvents.finished_at(@data),
        project_id: @links.fetch('project'),
        workflow_id: @links.fetch('workflow'),
        user_id: @links&.fetch('user', nil),
        user_group_ids: @data.fetch('metadata')&.fetch('user_group_ids', []),
        session_time: StreamEvents.session_time(@data),
        already_seen: StreamEvents.already_seen(@data)
      }
    end
  end
end
