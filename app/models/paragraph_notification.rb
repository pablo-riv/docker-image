class ParagraphNotification < ApplicationRecord
  has_many :text_notification
  has_many :notification, through: :text_notification
end
