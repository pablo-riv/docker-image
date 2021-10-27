module Slack
  class Insurance
    def initialize(team: '<@channel>')
      @client = Slack::Web::Client.new
      @team = '<@channel>'
    end

    def alert(message: '', channel: '#alerta_seguros')
      @client.chat_postMessage(channel: channel, text: message, as_user: true)
    end
  end
end
