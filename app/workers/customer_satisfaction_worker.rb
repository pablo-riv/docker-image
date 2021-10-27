class CustomerSatisfactionWorker
  include Sneakers::Worker
  from_queue 'core.customer_satisfaction'

  def work(data)
    puts "data #{data}"
    customer_satisfaction = JSON.parse(data)
    Sneakers::logger.info "Prepare customer satisfaction for #{customer_satisfaction}".green
    CreateCustomerSatisfactionWorker.perform_async(customer_satisfaction)
    ack!
  rescue StandardError => e
    ack!
  end
end
