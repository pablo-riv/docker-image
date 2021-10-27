class CompaniesWorker
  include Sneakers::Worker
  from_queue 'staff.set_company'

  def work(data)
    companies = JSON.parse(data)
    puts "#{companies.to_json}"
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    ack!
  ensure
    ack!
  end
end
