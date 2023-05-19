class ClassificationEvent < ApplicationRecord
    self.primary_keys = %i[event_time classification_id]
    validates :classification_id, presence: true
    validates :event_time, presence: true
end
