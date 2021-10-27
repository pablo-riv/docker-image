class V::ZendeskController < V::ApplicationController
  acts_as_token_authentication_handler_for Account, fallback_to_devise: false
  skip_before_action :verify_authenticity_token

  before_action :comments, only: %i[create]

  def create
    render json: { state: 200 } if generate_ticket
  end

  private

  def generate_ticket
    zendesk_attributes = zendesk_params.to_h.with_indifferent_access
    CreateTicketJob.perform_later(zendesk_attributes.merge(comments: @comments))
  rescue => e
    puts e.message.red
    false
  end

  def comments
    @comments = Zendesk::ZendeskService.new(zendesk_params.to_h.with_indifferent_access).extract_comments
  end

  def zendesk_params
    params.require(:ticket).permit(Support.zendesk_allowed_attributes)
  end
end
