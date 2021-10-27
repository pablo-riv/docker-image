class V::V2::TrackingsController < V::ApplicationController
  protect_from_forgery with: :null_session, raise: false
  before_action :set_package, only: %i[show]

  def show
    render json: @package, status: :ok
  rescue StandardError => e
    puts "#{e.message}\n#{e.backtrace[0]}".red.swap
    render json: { message: e.message, package: {}, state: :error }, status: :not_found
  end

  private

  def set_package
    @package = Package.select_tracking_data(params[:number])
    return {} unless @package.present?

    @package = @package.attributes.merge('estimated_delivery' => @package.estimated_delivery)
  end
end
