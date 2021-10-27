module SiteNotificable
  extend ActiveSupport::Concern
  included do
    after_create -> { create_notification }
  end

  def create_notification
    return if SiteNotification.find_by(actable_type: self.class.name, actable_id: id, status: notification_status).present?

    SiteNotification.create(notification_template)
    publish_notification
  rescue StandardError => e
    Rails.logger.info "ERROR: #{e} \n".red.swap
  end

  def publish_notification
    publisher = SuiteNotifications::Publish.new(channel: 'csat',
                                                company: company,
                                                dispatch: site_notification_params)
    publisher.publish
  end

  private

  def site_notification_params
    notification = site_notification.serializable_hash(include: %i[actable suite_notification])
    notification.merge({ ticket_id: site_notification.actable.support.ticket_id }) if site_notification.actable_type == 'CustomerSatisfaction'
    notification
  end

  def notification_template
    {
      actable_type: self.class.name,
      actable_id: id,
      status: notification_status,
      suite_notification_attributes: {
        title: I18n.t("notifications.site_notification.#{self.class.name.underscore}.#{notification_status}.title"),
        content: I18n.t("notifications.site_notification.#{self.class.name.underscore}.#{notification_status}.content"),
        company_id: company.id
      }
    }
  end

  def notification_status
    case self.class.name
    when 'Incidence', 'Pickup' then status
    else
      'base'
    end
  end
end
