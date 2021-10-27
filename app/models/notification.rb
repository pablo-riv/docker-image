class Notification < ApplicationRecord
  has_many :text_notification
  has_many :paragraph_notification, through: :text_notification

  accepts_nested_attributes_for :paragraph_notification
  #Notification.send({data: Package.first, type: :failed})
  # def self.send(params = {})
  #   new().deliver(params)
  # end

  def initialize
    @client = Slack::Web::Client.new
    @options = { email: true, slack: true }
    @channel = '#pedidos_fallidos'
    @url = "http://staff.shipit.cl/administration/packages/"
  end

  def deliver(params)
    @message = message(params[:type])
    @options.map {|option, value| send("#{option}_message".to_sym, params) if value }
  end

  def email_message(params)
    MailingMailer.send(params[:type].to_sym, params[:data]).deliver_later
  end

  def slack_message(params)
    @client.chat_postMessage(channel: @channel, text: "#{@message} #{params[:data].branch_office.company.name} / #{params[:data].reference}. El link del envío: #{@url}#{params[:data].id}", as_user: true)
  end

  def message(type)
    result =
      case type.to_sym
      when :delivered
      when :failed
        "🚨 Team hay un envío que falló, esta es la empresa y referencia:  "
      when :high_price
        "💰 Team hay un envío con precio muy alto, esta es la empresa y referencia: "
      when :delayed
        "🐢 Team este envío esta atrasado, esta es la empresa y referencia: "
      when :to_buyer
      else
      end
  end
end
