class V::V3::CalculatorController < V::ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_company
  before_action :set_algorithm, only: [:create]
  before_action :set_integration, only: [:create]
  before_action :set_ship, only: [:create]

  def create
    render json: @prices, status: 201
  end

  private

  def set_ship
    @prices = Calculator::Engine.calculate(
      courier_for_client: package_params[:courier_for_client],
      width: package_params[:width],
      height: package_params[:height],
      length: package_params[:length],
      weight: package_params[:weight],
      type_of_destiny: package_params[:type_of_destiny] || package_params[:destiny],
      type_of_payment: package_params[:is_payable] || package_params[:type_of_payment],
      destiny_id: package_params[:destiny_id] || package_params[:to_commune_id],
      origin_id: package_params[:origin_id],
      algorithm: algorithm,
      algorithm_days: algorithm_days,
      subscription: @company.current_subscription,
      apply_courier_discount: @company.apply_discount,
      company: @company,
      opit: @opit.configuration['opit'],
      integration: @integration,
      rate_from: package_params[:rate_from]
    )
    raise 'No obtuvimos precios bajo los parametros enviados' if @prices.nil?
  rescue StandardError => e
    render_rescue(e)
  end

  def set_algorithm
    @opit = Setting.opit(current_account.current_company.id)
  rescue StandardError => e
    render_rescue(e)
  end

  def algorithm
    package_params[:algorithm].present? ? package_params[:algorithm] : @opit.shipping_algorithm[:algorithm]
  end

  def algorithm_days
    package_params[:algorithm_days].present? ? package_params[:algorithm_days] : @opit.shipping_algorithm[:algorithm_days]
  end

  def set_integration
    @integration = Setting.fullit(current_account.current_company.id).seller_configuration(package_params[:rate_from])
  rescue StandardError => e
    render_rescue(e)
  end

  def set_company
    @company = company
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

  def package_params
    params.require(:package).permit(Calculator::Engine.allowed_attributes)
  end
end
