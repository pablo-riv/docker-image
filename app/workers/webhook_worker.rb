class WebhookWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5
  sidekiq_options queue: 'webhooks'

  def perform(webhook, model, kind_of_call, object_id)
    obj_to_send =
      case model
      when 'package' then Package.find_by(id: object_id)
      when 'sku' then object_id
      end
    raise 'Envio no encontrado' if model == 'package' && obj_to_send.blank?

    response = Webhook.new(webhook, model, 'application/json').send("#{kind_of_call}_model", obj_to_send)
    raise "Error sending this Webhook with status #{response.code}. #{webhook} #{kind_of_call}" if response.code != 200
  end
end
