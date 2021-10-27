class V::V2::ZendeskController < V::ApplicationController
  before_action :comments, only: %i[sync_tickets]
  before_action :params_for_update_ticket, only: %i[submit_message]
  after_action :sync_remote_ticket, only: %i[submit_message]

  def sync_tickets
    render json: { state: 200 } if generate_ticket
  end

  def submit_message
    @messages << Zendesk::ZendeskService.new(params, current_account).build_message
    @ticket.update_columns(messages: @messages, status: @ticket.status.gsub('Resuelto', 'Pendiente'))
    render json: { messages: @messages }
  end

  private

  def generate_ticket
    Zendesk::ZendeskService.new(params.merge(comments: @comments)).generate_or_update_ticket
  rescue => e
    puts e.message.red
    false
  end

  def comments
    @comments = Zendesk::ZendeskService.new(params).extract_comments
  end

  def params_for_update_ticket
    @ticket = Support.find_by(ticket_id: params[:ticket_id])
    @messages = @ticket.messages
  end

  def sync_remote_ticket
    Zendesk::ZendeskService.new(params, current_account).update_remote_ticket
  end
end
