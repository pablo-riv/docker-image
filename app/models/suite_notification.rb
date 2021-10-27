class SuiteNotification < ApplicationRecord
  # CALLBACKS
  after_create :dispatch_update

  # RELATIONS
  belongs_to :company
  belongs_to :notificable, polymorphic: true

  # SCOPES
  default_scope { where(is_archive: false) }

  # CLASS METHODS
  def self.allowed_attributes
    %i[title content notificable_type notificable_id company_id]
  end

  # INSTANCE METHODS
  def dispatch_update
    return if notificable.class.name == 'SiteNotification'

    publisher = SuiteNotifications::Publish.new(channel: 'message', company: company, dispatch: self)
    publisher.publish
  end
end
