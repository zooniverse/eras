# frozen_string_literal: true

module Kinesis
  class Create < ActiveInteraction::Base
    # 3 hour session time limit (10,800 seconds), capping at 30 mins (1800 seconds)
    SESSION_LIMIT = 10_800
    SESSION_CAP = 1800

    array :payload do
      hash strip: false
    end

    def execute
      comment_events = []
      classification_events = []
      classification_user_groups = []
      payload.each do |stream_event|
        process stream_event, comment_events, classification_events, classification_user_groups
      end

      CommentEvent.upsert_all(comment_events, unique_by: %i[comment_id event_time]) unless comment_events.empty?
      unless classification_events.empty?
        ClassificationEvent.upsert_all(classification_events,
                                       unique_by: %i[classification_id event_time])
      end
      # no primary key to upsert by, so we do an insert
      ClassificationUserGroup.insert_all(classification_user_groups.flatten) unless classification_user_groups.empty?
    end

    def process(stream_event, comment_events, classification_events, classification_user_groups)
      source = stream_event.fetch('source')
      type = stream_event.fetch('type')
      event_data = stream_event.fetch('data')
      comment_events << comment_event(event_data) if source == 'talk' && type == 'comment'
      return unless source == 'panoptes' && type == 'classification'

      classification_events << classification_event(event_data)
      add_classification_user_groups(event_data, classification_user_groups) if user_group_ids?(event_data)
    end

    private

    def comment_event(data)
      {
        comment_id: data.fetch('id'),
        event_time: data.fetch('created_at'),
        comment_updated_at: data&.fetch('updated_at', nil),
        project_id: data.fetch('project_id').to_i,
        user_id: data.fetch('user_id').to_i
      }
    end

    def classification_event(data)
      {
        classification_id: data.fetch('id'),
        event_time: data.fetch('created_at'),
        classification_updated_at: data.fetch('updated_at'),
        started_at: started_at(data),
        finished_at: finished_at(data),
        project_id: data.fetch('links').fetch('project'),
        workflow_id: data.fetch('links').fetch('workflow'),
        user_id: data.fetch('links').fetch('user'),
        user_group_ids: data.fetch('metadata').fetch('user_group_ids'),
        session_time: session_time(data)
      }
    end

    def user_group_ids?(event_data)
      event_data.fetch('links').fetch('user').present? &&
        event_data.fetch('metadata').fetch('user_group_ids').present?
    end

    def started_at(data)
      started_at = data.fetch('metadata')&.fetch('started_at', nil)
      DateTime.parse(started_at) if started_at
    end

    def finished_at(data)
      finished_at = data.fetch('metadata')&.fetch('finished_at', nil)
      DateTime.parse(finished_at) if finished_at
    end

    def session_time(data)
      started_at = started_at(data)
      finished_at = finished_at(data)
      diff = finished_at.to_i - started_at.to_i if finished_at && started_at
      diff = 0 if diff.negative?
      diff = SESSION_CAP if diff > SESSION_LIMIT
      diff.to_f
    end

    def classification_user_group(data, user_group_id)
      {
        classification_id: data.fetch('id'),
        event_time: data.fetch('created_at'),
        user_group_id:,
        session_time: session_time(data),
        project_id: data.fetch('links').fetch('project'),
        workflow_id: data.fetch('links').fetch('workflow'),
        user_id: data.fetch('links').fetch('user')
      }
    end

    def add_classification_user_groups(data, classification_user_groups)
      user_group_ids = data.fetch('metadata').fetch('user_group_ids')
      user_group_ids.each do |user_group_id|
        classification_user_groups << classification_user_group(data, user_group_id)
      end
    end
  end
end
