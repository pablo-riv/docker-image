module Help
  class ZendeskClient
    attr_accessor :client

    def initialize
      @client = setup_client
    end

    def create
      raise "can`t call abstract class"
    end

    def tickets
      raise "can`t call abstract class"
    end

    def ticket
      raise "can`t call abstract class"
    end

    def update_ticket(mgs)
      raise "can`t call abstract class"
    end

    def syncronize
      raise "can`t call abstract class"
    end

    private

    def setup_client
      ZendeskAPI::Client.new do |config|
       config.url = Rails.configuration.zendesk[:url]
       config.username = Rails.configuration.zendesk[:email]
       config.token = Rails.configuration.zendesk[:token]
       config.retry = true
       require 'logger'
       config.logger = Logger.new(STDOUT)
      end
    end
  end
end
