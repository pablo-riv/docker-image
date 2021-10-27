require 'uri'
require 'net/http'

class MercuryWhatsapp
  include HTTParty
  attr_accessor :attributes, :errors
  attr_reader :query, :body, :headers, :url
  def initialize(attributes)
    @attributes = attributes
    @errors = []
    @headers = { 'Content-Type' => 'application/json' }
    @query = { api_token: Rails.configuration.whatsapp[:api_token],
               instance: Rails.configuration.whatsapp[:instance] }
    @body = { phone: @attributes[:phone],
              body: @attributes[:body] }.to_json
    @url = 'https://api.mercury.chat/sdk/v1/whatsapp/sendMessage'
  end

  def send
    response = self.class.post(@url, { query: @query, body: @body, headers: @headers, verify: false })
    raise 'Message not delivered' if (400..422).cover?(response.code)

    response.parsed_response
  rescue => e
    # TODO: implement Slack alert
    Rails.logger.info "MESSAGE: #{e.message}\nBUGTRACE: #{e.backtrace[0]}".red.swap
  end
end
