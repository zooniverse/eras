class ClassificationUserGroup < ApplicationRecord
  self.primary_keys = %i[event_time classification_id user_group_id user_id]
end
