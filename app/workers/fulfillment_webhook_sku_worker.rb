class FulfillmentWebhookSkuWorker
  include Sneakers::Worker
  from_queue 'core.webhook_sku', env: nil, ack: true

  def work(data)
    sku = HashWithIndifferentAccess.new(JSON.parse(data))
    setting = Setting.fulfillment(sku[:company_id]).sku_webhook
    company = Company.find_by(id: sku[:company_id])
    raise 'Cliente no encontrado' unless company.present?

    SkuService.new(sku: sku,
                   kind_of_call: 'patch',
                   setting: setting,
                   company: company).send
    ack!
  rescue StandardError => e
    Sneakers::logger.info "webhook_worker: #{e.message}".red
    Rails.logger.info { "webhook_worker: #{e.message}".red }
    ack!
  ensure
    ack!
  end
end
