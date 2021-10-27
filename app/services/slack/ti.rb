module Slack
  class Ti
    attr_accessor :package

    def initialize(package, company, team = nil)
      @client = Slack::Web::Client.new
      @package = package
      @company = company
      @team = team || '<@channel>'
    end

    def alert(error = nil, message = nil, channel = '#ti_alert')
      message = message.nil? ? generate(error, message) : message
      @client.chat_postMessage(channel: channel, text: message, as_user: true)
    end

    def dispatch(message: '', backtrace: '', channel: '#ti_alert')
      @client.chat_postMessage(channel: channel, text: build_message(message, backtrace), as_user: true, link_names: true)
    end

    private

    attr_reader :message, :team, :company, :client, :error

    def generate(error, message = nil)
      @error = error
      message = default_alert if message.nil?
      "[#{Rails.env.capitalize}]\n#{@team}: #{message}"
    end

    def default_alert
      "Ha ocurrido un error: \n" \
      "COMPANY NAME: #{@company.name}\n " \
      "COMPANY ID: #{@company.id}\n " \
      "PACKAGE ID: #{@package.id}\n " \
      "PACKAGE REFERENCE: #{@package.reference}\n " \
      "PACKAGE TRACKING NUMBER: #{@package.tracking_number}\n " \
      "PACKAGE STATUS: #{@package.status}\n " \
      "PACKAGE CREATED AT: #{@package.created_at}\n " \
      "ERROR: #{@error}"
    end

    def build_message(message, backtrace)
      "[#{Rails.env.upcase}]\n#{@team} #{message} #{decorate_backtrace(backtrace)}"
    end

    def decorate_backtrace(backtrace)
      "\nBUGTRACE: ```\n#{backtrace&.first(3)&.join("\n")}\n```"
    rescue NoMethodError => _e
      ''
    end
  end
end
