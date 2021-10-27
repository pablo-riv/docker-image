class V::V2::CouriersController < V::ApplicationController
  before_action :set_couriers, only: [:index]

  def index
    render json: @couriers, status: :ok
  end

  private

  def set_couriers
    @couriers = Courier.where(available_to_ship: true)
  end
end
