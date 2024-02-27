# frozen_string_literal: true

class KinesisStream
  def initialize
    @comment_events = []
    @classification_events = []
    @classification_user_groups = []
  end

  def create_events(payload)
    receive(payload)

    upsert_comments unless @comment_events.empty?
    upsert_classifications unless @classification_events.empty?
    upsert_classification_user_groups unless @classification_user_groups.empty?
  end

  def upsert_comments
    @comment_events = @comment_events.uniq { |comment| comment[:comment_id] }
    CommentEvent.upsert_all(@comment_events, unique_by: %i[comment_id event_time])
  end

  def upsert_classifications
    @classification_events = @classification_events.uniq { |classification| classification[:classification_id] }
    ClassificationEvent.upsert_all(@classification_events, unique_by: %i[classification_id event_time])
  end

  def upsert_classification_user_groups
    @classification_user_groups = @classification_user_groups.uniq { |cug| [cug[:classification_id], cug[:user_group_id]] }
    ClassificationUserGroup.upsert_all(@classification_user_groups.flatten, unique_by: %i[classification_id event_time user_group_id user_id])
  end

  def receive(payload)
    ActiveRecord::Base.transaction do
      payload.each do |event|
        event_data = event.fetch('data')
        prepared_payload = StreamEvents.from(event).process
        @comment_events << prepared_payload if StreamEvents.comment_event?(event)

        next unless StreamEvents.classification_event?(event)

        @classification_events << prepared_payload
        add_classification_user_groups(event_data) if StreamEvents.user_group_ids?(event_data)
      end
    end
  end

  private

  def add_classification_user_groups(event_data)
    user_group_ids = event_data.fetch('metadata').fetch('user_group_ids')
    user_group_ids.uniq.each do |user_group_id|
      @classification_user_groups << StreamEvents::ClassificationUserGroup.new(event_data, user_group_id).process
    end
  end
end
