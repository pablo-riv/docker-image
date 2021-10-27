class SkusWorker
  include Sneakers::Worker
  from_queue 'ff.set_sku_core'

  def work(data)
    sku = JSON.parse(data).with_indifferent_access
    SkuService.get_sku(sku)
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    ack!
  ensure
    ack!
  end
end
