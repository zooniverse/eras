# frozen_string_literal: true

module StreamEvents
  # 3 hour session time limit (10,800 seconds), capping at 3 hours (10,800 seconds)
  SESSION_LIMIT = 10_800
  SESSION_CAP = 10_800

  def self.from(event)
    if comment_event?(event)
      StreamEvents::Comment.new(event)
    elsif classification_event?(event)
      StreamEvents::Classification.new(event)
    else
      StreamEvents::UnknownEvent.new
    end
  end

  def self.comment_event?(event)
    event.fetch('source') == 'talk' && event.fetch('type') == 'comment'
  end

  def self.classification_event?(event)
    event.fetch('source') == 'panoptes' && event.fetch('type') == 'classification'
  end

  def self.user_group_ids?(event_data)
    event_data.fetch('links').fetch('user').present? &&
      event_data.fetch('metadata').fetch('user_group_ids').present?
  end

  def self.started_at(event_data)
    started_at = event_data.fetch('metadata')&.fetch('started_at', nil)
    Time.parse(started_at) rescue nil if started_at
  end

  def self.finished_at(event_data)
    finished_at = event_data.fetch('metadata')&.fetch('finished_at', nil)
    Time.parse(finished_at) rescue nil if finished_at
  end

  def self.session_time(event_data)
    started_at = started_at(event_data)
    finished_at = finished_at(event_data)
    diff = finished_at - started_at if finished_at && started_at
    diff = 0 if diff.nil? || diff.negative?
    diff = SESSION_CAP if diff > SESSION_LIMIT
    diff
  end
end
