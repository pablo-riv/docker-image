module Zendesk
  class ZendeskService < Zendesk::Ticket
    attr_accessor :params, :account, :package

    def initialize(params = {}, current_account = nil)
      super(params, current_account)
    end

    def generate_or_update_ticket
      if Support.unscoped.where(ticket_id: ticket_id).size.zero?
        Support.create(build_hash)
      else
        update_ticket
      end
    rescue => e
      puts "Error al crear o actualizar ticket.\n Error: #{e.message}\n Trace: #{e.backtrace}"
    end

    def build_message
      { id: nil,
        type: 'Comment',
        message: message,
        author_id: account.zendesk_id.to_i,
        created_at: DateTime.now.to_s,
        name: "#{person.first_name} #{person.last_name}" }
    end

    def extract_comments
      comments
    end

    def update_remote_ticket
      Zendesk::Api.new(ticket_id).update_remote_ticket(message, account.zendesk_id.to_i)
    end

    def sync_tickets_by_organization(next_page = nil)
      Zendesk::Api.new(next_page).tickets_by_page
    end

    def remote_ticket
      Zendesk::Api.new(provider_id).show_ticket
    end

    private

    def build_hash
      { package_id: package_id,
        subject: subject,
        priority: priority,
        kind: kind,
        account_id: account_id,
        company_id: company.id,
        other_subject: other_subject,
        package_reference: package_reference,
        package_tracking: package_tracking,
        status: status,
        url: url,
        assignee_id: assignee_id,
        assignee_email: assignee_email,
        via: via,
        from_zendesk: from_zendesk,
        ticket_id: ticket_id,
        provider_id: provider_id,
        messages: messages,
        last_response_date: last_response_date,
        requester_type: requester_type,
        requester_email: requester_email,
        description: description,
        group_name: group_name,
        metrics: metrics,
        type_query_error: type_query_error }
    end

    def update_ticket
      ticket = Support.unscoped.find_by(ticket_id: ticket_id)
      ticket.update!(messages: messages,
                     last_response_date: last_response_date,
                     status: status,
                     requester_type: requester_type,
                     metrics: metrics,
                     type_query_error: type_query_error)
      ticket
    rescue => e
      'No fue posible actualizar el ticket'
    end
  end
end
