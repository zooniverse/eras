# frozen_string_literal: true

module StreamEvents
  class ClassificationUserGroup
    def initialize(event_data, user_group_id)
      @data = event_data
      @user_group_id = user_group_id
      @links = event_data.fetch('links')
    end

    def process
      {
        classification_id: @data.fetch('id'),
        event_time: @data.fetch('created_at'),
        user_group_id: @user_group_id,
        session_time: StreamEvents.session_time(@data),
        project_id: @links.fetch('project'),
        workflow_id: @links.fetch('workflow'),
        user_id: @links&.fetch('user', nil)
      }
    end
  end
end
