module Slack
  class Hubspot
    def initialize(team: '<@channel>')
      @client = Slack::Web::Client.new
      @team = '<@channel>'
    end

    def alert(message: 'Hay un error en la integracion de hubspot', channel: '#hubspot_errors')
      @client.chat_postMessage(channel: channel, text: message, as_user: true)
    end
  end
end
