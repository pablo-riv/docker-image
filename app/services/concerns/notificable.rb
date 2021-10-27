module Notificable
  extend ActiveSupport::Concern
  included do
    after_create -> { create_notification }
    after_update -> { create_notification }
  end

  def create_notification
    SuiteNotification.create(notification_template)
  rescue => e
    Rails.logger.info "ERROR: #{e} \n".red.swap
  end

  def notification_template
    {
      title: I18n.t("notifications.#{source}.title.#{status}"),
      content: I18n.t("notifications.#{source}.content.#{status}"),
      source: kind,
      status: status,
      readed: false,
      company_id: company_id
    }
  end

  def source
    self.class.name.downcase
  end
end
