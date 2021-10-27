class CouriersBranchOfficesController < ApplicationController
  def index
    render json: { state: :ok, couriers_branch_offices: Prices.new(current_account).branch_offices }, status: :ok
  rescue => e
    puts e.message.to_s.red
    render json: { state: :error }, status: :bad_request
  end
end
