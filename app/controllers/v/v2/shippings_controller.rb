class V::V2::ShippingsController < V::ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_ship, except: [:prices_v2]
  before_action :set_ship_v2, only: [:prices_v2]
  before_action :set_algorithm, only: [:prices_v2]
  before_action :set_price, only: [:prices_v2]

  def cost
    render json: @ship.shipment_cost, status: :ok
  end

  def costs
    render json: @ship.shipment_costs, status: :ok
  end

  def price
    render json: @ship.shipment_price, status: :ok
  end

  def prices
    render json: @ship.shipment_prices, status: :ok
  end

  def prices_v2
    render json: current_account.current_negotiation.apply(@prices), status: :ok
  end

  private

  def set_ship
    package = Package.new(package_params)
    @ship = Opit.new(package)
  end

  def set_ship_v2
    @ship = Opit.new(package_v2_params, false)
  end

  def set_algorithm
    @setting = Setting.opit(current_account.current_company.id)
  end

  def set_price
    data = @ship.shipment_costs_v2(current_account)
    @prices = AlgorithmService.new(subscription: current_account.current_company.current_subscription,
                                   apply_courier_discount: current_account.current_company.apply_discount,
                                   courier_for_client: package_params[:courier_for_client],
                                   prices: data['prices'],
                                   lower_price: data['lower_price'],
                                   higesth_price: data['higesth_price'],
                                   spreadsheet_versions: data['spreadsheet_versions'],
                                   spreadsheet_versions_destinations: data['spreadsheet_versions_destinations'],
                                   algorithm: package_params[:algorithm].presence || @setting.shipping_algorithm[:algorithm],
                                   algorithm_days: package_params[:algorithm_days].presence || @setting.shipping_algorithm[:algorithm_days]).calculate
  end

  def package_params
    params.require(:package).permit(Package.allowed_attributes)
  end

  def package_v2_params
    params.require(:package).permit(:commune_from_id, :commune_to_id, :length, :width, :height, :weight, :is_payable, :algorithm, :algorithm_days, :destiny, :courier_selected, :courier_for_client)
  end
end
