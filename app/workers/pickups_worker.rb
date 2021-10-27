class PickupsWorker
  include Sneakers::Worker
  from_queue 'pp.by_pickup', env: nil, ack: true

  def work(data)
    puts "pickup: #{data}".green
    puts "parsed: #{JSON.parse(data)}".blue
    pickup = JSON.parse(data)
    PackageService.all_by_pickup(pickup)
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    ack!
  ensure
    ack!
  end

end
