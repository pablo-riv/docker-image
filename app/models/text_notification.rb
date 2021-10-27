class TextNotification < ApplicationRecord
  belongs_to :notification
  belongs_to :paragraph_notification
end
