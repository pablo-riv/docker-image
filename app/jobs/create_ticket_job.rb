class CreateTicketJob < ApplicationJob
  queue_as :default

  def perform(ticket_object)
    Zendesk::ZendeskService.new(ticket_object).generate_or_update_ticket
  rescue StandardError => e
    Rails.logger.info { "#{e.message}\n#{e.backtrace[0]}".red.swap }
  end
end
