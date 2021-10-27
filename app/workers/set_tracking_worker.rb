class SetTrackingWorker
  include Sneakers::Worker

  from_queue 'core.set_tracking', env: nil

  def work(data)
    object = JSON.parse(data)
    Sneakers::logger.info "Packages received for set tracking: #{object['ids']}".cyan
    Package.where(id: object['ids']).each{ |package| package.try(:set_tracking) unless package.blank? } unless object['ids'].blank?
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    Publisher.publish('status_log', { message: "staff.set_tracking: #{e.message}" })
    ack!
  end
end
