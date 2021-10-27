class V::V4::CalculatorController < V::ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_company
  before_action :set_order, only: %i[create]
  before_action :set_orders, only: %i[massive]
  before_action :set_algorithm, only: %i[create massive quotations]
  before_action :set_integration, only: %i[create massive quotations]
  before_action :set_quotation, only: %i[quotations]
  before_action :set_ship, only: %i[create]

  def create
    render json: @prices, status: 201
  end

  def massive
    @prices = @orders.map do |order|
      ship = Opit.new(calculator_template(order), false)
      data = ship.prices(current_account)
      { id: order.id,
        prices: AlgorithmService.new(subscription: current_account.current_company.current_subscription,
                                     apply_courier_discount: current_account.current_company.apply_discount,
                                     courier_for_client: order.courier['client'],
                                     prices: data['prices'],
                                     lower_price: data['lower_price'],
                                     higesth_price: data['higesth_price'],
                                     spreadsheet_versions: data['spreadsheet_versions'],
                                     spreadsheet_versions_destinations: data['spreadsheet_versions_destinations'],
                                     algorithm: order.courier[:algorithm].presence || @setting.shipping_algorithm[:algorithm],
                                     algorithm_days: order.courier[:algorithm_days].presence || @setting.shipping_algorithm[:algorithm_days]).calculate }
    end
    render json: @prices, status: 201
  end

  def quotations
    render json: @prices, status: 201
  end

  private

  def set_quotation
    @prices = Calculator::Engine.calculate(
      courier_for_client: shipment_params[:courier_for_client],
      width: shipment_params[:width],
      height: shipment_params[:height],
      length: shipment_params[:length],
      weight: shipment_params[:weight],
      type_of_destiny: shipment_params[:type_of_destiny] || shipment_params[:destiny],
      type_of_payment: shipment_params[:is_payable] || shipment_params[:type_of_payment],
      destiny_id: shipment_params[:destiny_id] || shipment_params[:to_commune_id],
      origin_id: shipment_params[:origin_id],
      algorithm: algorithm,
      algorithm_days: algorithm_days,
      subscription: @company.current_subscription,
      apply_courier_discount: @company.apply_discount,
      company: @company,
      opit: @opit.configuration['opit'],
      integration: @integration,
      rate_from: shipment_params[:rate_from]
    )
    raise 'No obtuvimos precios bajo los parametros enviados' if @prices.nil?
  rescue StandardError => e
    render_rescue(e)
  end

  def set_company
    @company = company
  end

  def set_ship
    @ship = Opit.new(calculator_template(@order), false)
  end

  def set_algorithm
    @opit = Setting.opit(current_account.current_company.id)
  end

  def algorithm
    return @order.courier.algorithm if @order.present?

    shipment_params[:algorithm].present? ? shipment_params[:algorithm] : @opit.shipping_algorithm[:algorithm]
  end

  def algorithm_days
    return @order.courier.algorithm_days if @order.present?

    shipment_params[:algorithm_days].present? ? shipment_params[:algorithm_days] : @opit.shipping_algorithm[:algorithm_days]
  end

  def set_integration
    @integration = Setting.fullit(current_account.current_company.id).seller_configuration(shipment_params[:rate_from])
  rescue StandardError => e
    render_rescue(e)
  end

  def calculator_template(order)
    { length: order.sizes['length'].present? && order.sizes['length'].to_f >= 0.01 ? order.sizes['length'].to_f : 10.0,
      width: order.sizes['width'].present? && order.sizes['width'].to_f >= 0.01 ? order.sizes['width'].to_f : 10.0,
      height: order.sizes['height'].present? && order.sizes['height'].to_f >= 0.01 ? order.sizes['height'].to_f : 10.0,
      weight: order.sizes['weight'].present? && order.sizes['weight'].to_f >= 0.01 ? order.sizes['weight'].to_f : 1.0,
      algorithm: order.courier['algorithm'].presence || 1,
      algorithm_days: order.courier['algorithm_days'].presence || nil,
      to_commune_id: order.destiny['commune_id'],
      is_payable: false,
      destiny: 'domicilio',
      courier_selected: false,
      courier_for_client: order.courier['client'] }.with_indifferent_access
  end

  def set_order
    @order = company.orders.find_by(id: params[:order][:id]) if params[:order][:id]
    raise 'Orden no encontrada' unless @order.present?
  rescue StandardError => e
    render_rescue(e)
  end

  def set_orders
    @orders = company.orders.where(id: params[:orders][:ids]) if params[:orders][:ids]
  rescue StandardError => e
    render_rescue(e)
  end

  def shipment_params
    params.require(:shipment).permit(Calculator::Engine.allowed_attributes)
  end

  def packages_params
    params.require(:packages).map do |package|
      package.permit(Calculator::Engine.allowed_attributes)
    end
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { courier_for_client: '',
                   prices: [],
                   lower_price: {},
                   algorithm: '',
                   algorithm_days: '',
                   message: exception.message,
                   state: :error },
           status: :bad_request
  end
end
