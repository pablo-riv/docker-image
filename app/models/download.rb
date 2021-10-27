class Download < ApplicationRecord
  include Notificable

  after_create :dispatch_update
  after_update :dispatch_update

  belongs_to :company

  enum kind: { label: 0, xlsx: 1, image: 2, docx: 3, orders: 4, manifest: 5, pdf: 6 }, _prefix: 'download'
  enum status: { pending: 0, init: 1, downloading: 2, success: 3, failed: 4 }, _prefix: 'download'

  default_scope { where(is_archive: false) }

  private

  def dispatch_update
    publisher = SuiteNotifications::Publish.new(channel: 'download', company: company, dispatch: self)
    publisher.publish
  end
end
