# frozen_string_literal: true

class CommentEvent < ApplicationRecord
  self.primary_keys = %i[event_time comment_id]
  validates :comment_id, presence: true
  validates :event_time, presence: true
end
