require 'zendesk_api'
module Help
  class ZendeskTicket < ZendeskClient
    attr_accessor :issue

    def initialize(properties)
      @issue = Issue.new(properties)
      super() # need to specify braces or raise an exception wtf?
    end

    # create ticket by account
    def create
      client.tickets.create!(subject: "#{issue.subject}: #{issue.other_subject}",
                             comment: { value: issue.message },
                             description: issue.message,
                             priority: issue.priority,
                             external_id: issue.internal_id,
                             type: issue.type,
                             requester_id: issue.zendesk_id,
                             submitter_id: issue.zendesk_id,
                             assignee_id: issue.assign,
                             ticket_form_id: 360000153994,
                             custom_fields: custom_fields({ tracking_number: issue.package.try(:tracking_number),
                                                            package_id: issue.package.try(:id),
                                                            other_subject: issue.other_subject,
                                                            subject: issue.subject,
                                                            package_status: package_status,
                                                            package_courier: issue.package.try(:courier_for_client),
                                                            staff_link: staff_link,
                                                            requester_type: issue.requester_type,
                                                            courier_link: issue.package.try(:courier_tracking_link) }))
    end

    # query tickets by account
    def tickets(ids)
      client.tickets.show_many(ids: ids,
                               requester_id: issue.zendesk_id,
                               submitter_id: issue.zendesk_id)
    end

    # query ticket by account
    def ticket
      client.tickets(include: :comments).find(id: issue.provider_id,
                                              requester_id: issue.zendesk_id,
                                              submitter_id: issue.zendesk_id)
    end

    # update ticket by account
    # it pass a new commet as agent not an end-user
    # so end-users only leave commets via email
    def update_ticket(msg)
      client.tickets.update(id: issue.provider_id,
                            author_id: issue.zendesk_id,
                            requester_id: issue.zendesk_id,
                            submitter_id: issue.zendesk_id,
                            comment: { value: msg },
                            description: msg,
                            is_public: true)
    end

    def syncronize
      client.search(query: "requester_id:#{issue.zendesk_id} type:ticket").each do |ticket|
        local_ticket = ::Support.find_or_create_by(provider_id: ticket.id, account_id: issue.account.id)
        next unless local_ticket.present?
        unless local_ticket.status.nil?
          next if local_ticket.status.include?('solved') || local_ticket.status.include?('closed')
        end
        local_ticket.update(messages: build_messages(ticket),
                            status: ticket.status,
                            subject: ticket.subject,
                            kind: I18n.t("helps.type.#{ticket.type}"),
                            priority: ticket.priority,
                            url: ticket.url,
                            via: ticket.via[:channel],
                            last_response_name: ticket.comments.last.author.name,
                            last_response_date: ticket.comments.last.created_at)
      end
    end

    private

    def custom_fields(object)
      [{ id: 360007200813, value: object[:subject].downcase.tr(' ', '_') },
       { id: 360007200833, value: object[:other_subject].downcase.tr(' ', '_') },
       { id: 360035772033, value: object[:tracking_number] },
       { id: 360007279854, value: object[:package_id] },
       { id: 360008034573, value: object[:package_status], },
       { id: 360008113234, value: object[:package_courier], },
       { id: 360008113254, value: object[:staff_link], },
       { id: 360030457754, value: object[:requester_type], },
       { id: 360008113274, value: object[:courier_link] }]
    end

    def staff_link
      issue.package.present? ? issue.package.staff_link : ''
    end

    def package_status
      issue.package.present? ? I18n.t("activerecord.attributes.package.statuses.#{issue.package.status}") : ''
    end

    def build_messages(ticket)
      ticket.comments.map { |comment| { 'name' => comment.author.name, 'user' => comment.author.role_id.underscore, 'message' => comment.html_body, 'created_at' => comment.created_at.strftime('%H:%M:%S %d-%m-%Y') } }
    end
  end
end
