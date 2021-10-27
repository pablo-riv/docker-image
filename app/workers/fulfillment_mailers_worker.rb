class FulfillmentMailersWorker
  include Sneakers::Worker
  from_queue 'ff.mailer', env: nil, ack: true

  def work(data)
    message = JSON.parse(data)
    notification = Company.find_by(id: message['sku']['company_id']).notification_settings.fulfillment_notification
    Sneakers::logger.info "ALERT TYPE: #{message['type']}, EMAIL: #{notification['email']}".green
    NotificationMailer.send(message['type'], { 'email' => notification['email'], 'sku' => message['sku'] }).deliver if notification[message['type']]
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    ack!
  end
end
