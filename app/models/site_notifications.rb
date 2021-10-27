class SiteNotification < ApplicationRecord
  # RELATIONS
  has_one :suite_notification, as: :notificable
  belongs_to :actable, polymorphic: true

  accepts_nested_attributes_for :suite_notification

  # VALIDATIONS
  validates :suite_notification, presence: true

  default_scope { includes(:suite_notification).where(suite_notifications: {is_archive: false}) }

  # SCOPES
  def self.allowed_attributes
    [:actable_id, :actable_type, { suite_notification_attributes: SuiteNotification.allowed_attributes }]
  end
end
