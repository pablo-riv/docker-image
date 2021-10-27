module Zendesk
  class TicketTemplate
    def initialize(attributes)
      @attributes = attributes
    end

    def ticket_client_struct(kind)
      company = Package.find(@attributes['id']).company
      {
        ticket: {
          subject: Zendesk::Title.new(@attributes['reference']).send(kind),
          status: 'pending',
          requester_id: company.current_account&.zendesk_id,
          submitter_id: Rails.configuration.zendesk_bot_data[:submitter_id],
          assignee_id: Rails.configuration.zendesk_bot_data[:assignee_id],
          group_id: Rails.configuration.zendesk_bot_data[:group_id],
          comment: {
            html_body: Zendesk::Message.new(@attributes).send(kind),
            public: true
          },
          custom_fields: [{ id: 360_007_279_854, value: (@attributes['id']) },
                          { id: 360_035_772_033, value: (@attributes['tracking_number']) },
                          { id: 360_035_860_254, value: (@attributes['reference']) }],
          tags: Zendesk::Tag.new(@attributes).send(kind)
        }
      }
    end

    def ticket_courier_struct(kind)
      courier_data = Zendesk::CourierInfo.new(@attributes['courier_for_client'])
                                         .courier_data
      return false unless courier_data
      {
        ticket: {
          subject: Zendesk::Title.new(@attributes['tracking_number']).send(kind),
          status: 'pending',
          requester_id: courier_data[:requester_id],
          submitter_id: Rails.configuration.zendesk_bot_data[:submitter_id],
          assignee_id: Rails.configuration.zendesk_bot_data[:assignee_id],
          group_id: Rails.configuration.zendesk_bot_data[:group_id],
          comment: {
            html_body: Zendesk::Message.new(@attributes, courier_data[:agent_name]).send(kind),
            public: true,
            uploads: @attributes['zendesk_documents']
          },
          custom_fields: [{ id: 360_007_279_854, value: (@attributes['id']) },
                          { id: 360_035_772_033, value: (@attributes['tracking_number']) }],
          tags: Zendesk::Tag.new(@attributes).send(kind)
        }
      }
    end
  end
end
