class StaffRetryFfSignal
  include Sneakers::Worker

  from_queue 'core.retry_fulfillment', env: nil

  def work(data)
    Sneakers::logger.info '============= INIT STAFF FF RETRY SIGNAL ============='.yellow
    result = JSON.parse(data)
    package = Package.find_by(id: result['id'])
    raise 'Envio no encontrado StaffRetryFfSignal' unless package.present?

    Sneakers::logger.info "=============  PACKAGE: #{package.id} =============".yellow
    Sneakers::logger.info "=============  INVENTORY ACTIVITY: #{package.inventory_activity} =============".yellow
    package.retry_fulfillment
    Sneakers::logger.info '============= END STAFF FF RETRY SIGNAL ============='.yellow
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    ack!
  ensure
    ack!
  end
end
