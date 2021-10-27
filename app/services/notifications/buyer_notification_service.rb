module Notifications
  class BuyerNotificationService
    def self.dispatch(package, status = nil)
      return { alert: nil, success: false, message: 'Package es requerido' } unless package.present?

      status ||= package.status
      check_pending_alerts(package.alerts)
      return { alert: nil, success: true, message: 'Alerta no requerida para el estado del package' } unless requires_notification?(status)

      alert = package.alerts.find_by(state: status)
      alert = Alert.create(state: status, status: :created, package_id: package.id) if alert.blank?
      return { alert: alert, success: false, message: 'Alerta ya enviada' } if alert.email_sent?

      publish(alert)
      { alert: alert, success: true, message: 'Alerta generada' }
    rescue StandardError => e
      log_exception('[dispatch]', e)
    end

    def self.check_pending_alerts(alerts = nil)
      alerts ||= Alert.where(alerts: { created_at: (Time.now - 3.days)..(Time.now - 5.minutes) })
      alerts = alerts.pendings
      alerts.each do |alert|
        publish(alert)
      end
    rescue StandardError => e
      log_exception('[check_pending_alerts]', e)
    end

    def self.publish(alert)
      payload = { package_id: alert.package_id,
                  status: alert.state,
                  alert_id: alert.id }
      exchange = alert.email_template.present? ? 'buyer_email' : 'buyer_email_create'
      Publisher.publish(exchange, payload)
    rescue StandardError => e
      log_exception('[publish]', e)
    end

    def self.requires_notification?(status)
      %w[in_preparation in_route delivered failed by_retired].include?(status.try(:to_s))
    end

    private

    def log_exception(tag, exception)
      error_msg = "#{tag} ERROR: #{exception.message}\nBUGTRACE: #{exception.backtrace[0]}"
      Rails.logger.info(error_msg.red.swap)
      Slack::Ti.new&.dispatch(message: "**BuyerNotificationService**\n#{error_msg}",
                              backtrace: exception.backtrace)
    end
  end
end
