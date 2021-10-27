class NegotiationsController < ApplicationController
  before_action :set_negotiation, only: [:show]

  def show
    render json: { negotiation: @negotiation, state: :ok }, status: :ok
  rescue => e
    render json: { negotiation: {}, state: :error }, status: :bad_request
  end

  private

  def set_negotiation
    @negotiation = current_account.current_company.negotiation
  end
end
