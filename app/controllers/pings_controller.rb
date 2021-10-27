class PingsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:index]
  skip_before_action :authenticate_account!, raise: false, only: [:index]
  def index
    render json: { status: :ok }, status: :ok
  end
end
