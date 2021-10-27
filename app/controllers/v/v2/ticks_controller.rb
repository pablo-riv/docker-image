class V::V2::TicksController < V::ApplicationController
  def tacks
    render json: { state: :ok }, status: :ok
  end
end
