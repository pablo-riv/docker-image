module SuiteNotifications
  class Publish
    attr_accessor :dispatch, :company, :channel, :errors
    def initialize(channel: '', company: {}, dispatch: {})
      @channel = channel
      @company = company
      @dispatch = dispatch
      @client = Redis.new(client)
      @errors = []
    end

    def publish
      @client.publish("#{@channel}_#{@company.id}", @dispatch.to_json)
    rescue => e
      puts e.message.red
    end

    private

    def client
      Rails.configuration.redis_url.present? ? { url: Rails.configuration.redis_url } : { host: Rails.configuration.redis_host }
    end
  end
end
