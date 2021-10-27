class DownloadNotification < ApplicationRecord
  # RELATIONS
  has_one :suite_notification, as: :notificable

  # TYPES
  enum source: { label: 0, xlsx: 1, image: 2, docx: 3, orders: 4, manifest: 5, pdf: 6 }, _prefix: :source
  enum status: { pending: 0, init: 1, downloading: 2, success: 3, failed: 4 }, _prefix: :status

  accepts_nested_attributes_for :suite_notification

  # VALIDATIONS
  validates :suite_notification, presence: true

  # SCOPES
  def self.allowed_attributes
    [:source, :status, { suite_notification_attributes: SuiteNotification.allowed_attributes }]
  end
end
