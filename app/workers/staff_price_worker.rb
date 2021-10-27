class StaffPriceWorker
  include Sneakers::Worker

  from_queue "staff.set_price", env: nil

  def work(data)
    package = JSON.parse(data)
    Package.find(package['id']).set_price
    puts package.to_json
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    ack!
  ensure
    ack!
  end
end
