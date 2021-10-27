class SiteNotification < ApplicationRecord
  # RELATIONS
  has_one :suite_notification, as: :notificable
  belongs_to :actable, polymorphic: true

  accepts_nested_attributes_for :suite_notification

  # VALIDATIONS
  validates :suite_notification, presence: true

end
