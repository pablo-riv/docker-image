class CreateCustomerSatisfactionWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 5, backtrace: true

  sidekiq_retry_in do |count, exception|
    puts "Cant create customer satisfaction: #{exception.message}".yellow
    900 # Time in seconds, 15 minutes
  end

  def perform(args)
    puts "args #{args}"
    if args['password'].blank?
      account = Account.find_by(email: args['email'])
      args['password'] = Zendesk::Api.new(account.zendesk_id).create_password_to_end_user
      account.update zendesk_password: args['password']
    end
    Zendesk::Api.new(args['ticket_id']).create_satisfaction_rating(args['email'],
                                                                   args['password'],
                                                                   args['response'],
                                                                   args['comment'])
  end
end
