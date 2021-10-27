class CreateChangePackageAddressWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, backtrace: true

  sidekiq_retry_in do |_count, exception|
    puts "Cant create ticket for change address: #{exception.message}".yellow
    900 # Time in seconds, 15 minutes
  end

  def perform(type, args, kind)
    Zendesk::Api.new.create_ticket(type, args, kind)
  end
end
