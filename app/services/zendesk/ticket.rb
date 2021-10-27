module Zendesk
  class Ticket
    include Zendesk::Comment
    include Zendesk::Authenticator
    include Zendesk::Requester
    include Zendesk::Metrics

    attr_accessor :params, :package, :basic_auth, :account, :authors_recognized, :ticket

    def initialize(params = {}, current_account = nil)
      @params = params
      @package = find_package
      @basic_auth = auth
      @account = current_account
      @authors_recognized = []
      @ticket = nil
    end

    def support
      params
    end

    def subject
      support[:subject]
    end

    def priority
      support[:priority]
    end

    def kind
      support[:kind]
    end

    def other_subject
      support[:other_subject]
    end

    def status
      support[:status]
    end

    def url
      support[:url]
    end

    def assignee_id
      support[:assignee_id]
    end

    def assignee_email
      support[:assignee_id]
    end

    def via
      support[:via]
    end

    def from_zendesk
      support[:from_zendesk]
    end

    def provider_id
      support[:provider_id]
    end

    def requester_email
      support[:requester_email]
    end

    def description
      support[:ticket_description]
    end

    def group_name
      support[:ticket_group_name]
    end

    def package_id
      support[:package_id] || package[:id]
    end

    def find_package
      Package.find(package_id)
    rescue StandardError => _e
      {}
    end

    def account_id
      account.nil? ? package.company.current_account.id : account.id
    rescue StandardError => _e
      1
    end

    def message
      params[:message]
    end

    def messages
      build_comments
    end

    def package_tracking
      package[:tracking_number]
    end

    def package_reference
      package[:reference]
    end

    def ticket_id
      support[:ticket_id] || params[:id]
    end

    def last_response_date
      support[:comments].last['created_at']
    rescue StandardError => _e
      support[:created_at]
    end

    def requester_type
      extract_requester_type
    end

    def metrics
      raw_metrics = Zendesk::Api.new(ticket_id).metrics
      return { error: raw_metrics } if raw_metrics.is_a?(String)

      format_metrics(raw_metrics)
    end

    def comments
      zendesk_comments
    end

    def person
      account.person
    end

    def company
      contact = Contact.find_by(email: requester_email)
      contact.present? ? contact.company : Company.first
    end

    def type_query_error
      support[:type_query_error] || support[:custom_fields].select { |cf| cf[:id] == 360001500853 }.first[:value]
    end
  end
end
