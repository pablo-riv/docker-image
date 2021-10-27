class V::V4::Tickets::ZendeskController < V::ApplicationController
  before_action :set_params_for_update_ticket, only: %i[submit_message]
  after_action :sync_remote_ticket, only: %i[submit_message]

  def submit_message
    @messages << Zendesk::ZendeskService.new(params[:ticket], current_account).build_message
    @ticket.update_columns(messages: @messages, status: @ticket.status.gsub('Resuelto', 'Pendiente'))
    render json: { messages: @messages }
  end

  private

  def set_params_for_update_ticket
    @ticket = Support.find_by(provider_id: params[:ticket][:ticket_id])
    @messages = @ticket.messages
  end

  def sync_remote_ticket
    Zendesk::ZendeskService.new(params[:ticket], current_account).update_remote_ticket
  end
end
