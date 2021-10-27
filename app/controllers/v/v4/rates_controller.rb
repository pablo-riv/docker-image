class V::V4::RatesController < V::ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_company, only: %i[create]
  before_action :set_algorithm, only: %i[create]
  before_action :set_integration, only: %i[create]
  before_action :set_rate, only: %i[create]

  def create
    render json: @prices, status: 200
  rescue StandardError => e
    render_rescue(e)
  end

  private

  def set_rate
    @prices = Calculator::Engine.calculate(
      courier_for_client: parcel_params[:courier_for_client],
      width: parcel_params[:width],
      height: parcel_params[:height],
      length: parcel_params[:length],
      weight: parcel_params[:weight],
      type_of_destiny: parcel_params[:type_of_payment]|| parcel_params[:is_payable],
      type_of_payment: parcel_params[:type_of_payment],
      destiny_id: parcel_params[:destiny_id],
      origin_id: parcel_params[:origin_id],
      algorithm: algorithm,
      algorithm_days: algorithm_days,
      subscription: @company.current_subscription,
      apply_courier_discount: @company.apply_discount,
      company: @company,
      opit: @opit.configuration['opit'],
      integration: @integration,
      rate_from: parcel_params[:rate_from]
    )
    raise 'No obtuvimos precios bajo los parametros enviados' if @prices.nil?
  rescue StandardError => e
    render_rescue(e)
  end

  def set_algorithm
    @opit = Setting.opit(current_account.current_company.id)
  end

  def algorithm
    parcel_params[:algorithm].present? ? parcel_params[:algorithm] : @opit.shipping_algorithm[:algorithm]
  end

  def algorithm_days
    parcel_params[:algorithm_days].present? ? parcel_params[:algorithm_days] : @opit.shipping_algorithm[:algorithm_days]
  end

  def set_integration
    @integration = Setting.fullit(current_account.current_company.id).seller_configuration(parcel_params[:rate_from])
  rescue StandardError => e
    render_rescue(e)
  end

  def set_company
    @company = company
  end

  def parcel_params
    params.require(:parcel).permit(Calculator::Engine.allowed_attributes)
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
