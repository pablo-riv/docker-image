class SkuService
  attr_accessor :object, :errors
  def initialize(object)
    @object = object
    @errors = []
  end

  def send
    validate_properties
    raise StandardError unless @errors.size.zero?

    webhook_sku
  rescue StandardError => e
    puts "#{e.message}\n#{e.backtrace[0]}".red.swap
  end

  private

  def validate_properties
    @errors << 'Sin Sku' unless @object.present?
    @errors << 'Sin Webhook configurado' unless setting['url'].present?
  end

  def webhook_sku
    webhook_notification = WebhookNotification.create(model_id: sku['id'],
                                                      model_sent: 'Sku',
                                                      kind_of_call: kind_of_call,
                                                      url_sent: setting['url'],
                                                      tries_made: 0,
                                                      max_retries: 5,
                                                      success: false)
    Publisher.publish('sku_webhook', company: company.notification_serialize_data,
                                     webhook_notification: webhook_notification.attributes,
                                     setting: setting,
                                     data: sku)
  rescue StandardError => e
    e.message
  end

  def sku
    @object[:sku]
  end

  def kind_of_call
    @object[:kind_of_call]
  end

  def setting
    @object[:setting]
  end

  def company
    @object[:company]
  end
end
