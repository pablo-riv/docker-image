class PackageStatusWorker
  include Sneakers::Worker
  from_queue 'core.package_status_from_opit', env: nil, ack: true

  def work(id)
    Sneakers::logger.info id.to_s.blue
    package = Package.find_by(id: id)
    raise 'Envio no encontrado PackageStatusWorker' unless package.present?

    package.notifications_mails
    package.update_seller if !package.blank? && package.seller_package?
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    ack!
  ensure
    ack!
  end
end
