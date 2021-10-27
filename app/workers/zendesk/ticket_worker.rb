class TicketWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, backtrace: true

  sidekiq_retry_in do |_count, exception|
    puts "Can't create ticket: #{exception.message}".yellow
    900 # Time in seconds, 15 minutes
  end

  def perform(user_type, args, kind)
    response = Zendesk::Api.new.create_ticket(user_type, args, kind)
    support = Support.create(subject: response['subject'],
                             from_zendesk: false,
                             account_id: 1,
                             other_subject: 'autogestión',
                             package_id: args['id'],
                             provider_id: response['id'],
                             requester_type: 'other_agent',
                             ticket_id: response[:id].to_i,
                             url: response['url'],
                             via: response['via']['channel'],
                             status: response['status'],
                             priority: response['priority'],
                             kind: I18n.t("helps.type.#{response['type']}"))
    incidence = Incidence.find_by(id: args['incidence_id'])
    incidence.supports << support
  end
end
