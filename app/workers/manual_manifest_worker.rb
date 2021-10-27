class ManualManifestWorker
  include Sneakers::Worker
  from_queue 'core.manual_manifest', env: nil, ack: true

  def work(object)
    data = HashWithIndifferentAccess.new(JSON.parse(object))
    pickup = Pickup.find_by(id: data[:id])
    raise 'Pickup no encontrado' unless pickup.present?

    pickup.generate_manifest
    pickup.reload
    pickup.dispatch_manifest
    ack!
  rescue StandardError => e
    Sneakers::logger.info "webhook_worker: #{e.message}\nError: #{e.backtrace}".red
    Rails.logger.info { "webhook_worker: #{e.message}".red }
    ack!
  ensure
    ack!
  end
end
