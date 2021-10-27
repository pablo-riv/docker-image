class ManifestWorker
  include Sneakers::Worker
  from_queue 'core.create_manifest', env: nil, ack: true

  def work(object)
    data = HashWithIndifferentAccess.new(JSON.parse(object))
    ManifestJob.perform_later(data)
    ack!
  rescue StandardError => e
    Sneakers::logger.info "webhook_worker: #{e.message}\nError: #{e.backtrace}".red
    Rails.logger.info { "webhook_worker: #{e.message}".red }
    ack!
  ensure
    ack!
  end
end
