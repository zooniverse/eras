# frozen_string_literal: true

class KinesisStream
  def initialize
    @comment_events = []
    @classification_events = []
    @classification_user_groups = []
  end

  def create_events(payload)
    receive(payload)
    # TO DO (possibly?): We may want to consider doing these upserts/inserts in batches to improve performance.
    CommentEvent.upsert_all(@comment_events, unique_by: %i[comment_id event_time]) unless @comment_events.empty?
    unless @classification_events.empty?
      ClassificationEvent.upsert_all(@classification_events,
                                     unique_by: %i[classification_id event_time])
    end
    # no primary key to upsert by, so we do an insert
    ClassificationUserGroup.insert_all(@classification_user_groups.flatten) unless @classification_user_groups.empty?
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
    user_group_ids.each do |user_group_id|
      @classification_user_groups << StreamEvents::ClassificationUserGroup.new(event_data, user_group_id).process
    end
  end
end
