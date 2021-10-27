module Slack
  class CustomCheckout
    def initialize(team: '@channel')
      @client = Slack::Web::Client.new
      @team = team
    end

    def alert(message: '', channel: '#custom_checkout')
      @client.chat_postMessage(channel: channel, text: message, as_user: true)
    end
  end
end
