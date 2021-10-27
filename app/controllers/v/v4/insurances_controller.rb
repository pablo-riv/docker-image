class V::V4::InsurancesController < V::ApplicationController
  before_action :set_company
  before_action :set_insurance, only: %i(show update destroy)
  before_action :set_insurances, only: %i(index)
  before_action :set_automatization, only: %i(create update)

  def index
    respond_with(@insurances)
  end

  def show
    respond_with(@insurance)
  end

  def create
    Insurance.transaction do
      shipment = Package.find_by(id: insurance_params[:package_id])
      raise "Envío cuenta con seguro: ID #{shipment.insurance.id}" if (shipment.present? && shipment.insurance.present?) 
      raise 'Envío no encontrado' unless shipment.present?

      InsuranceService.new(id: shipment.id,
                           courier_for_client: shipment.courier_for_client,
                           insurance: nil,
                           company: shipment.company,
                           automatization: @automatization).active
      respond_with(shipment.insurance)
    end
  rescue => e
    render_rescue(e)
  end

  def update
    Insurance.transaction do
      raise unless @insurance.update(insurance_edit_params)

      shipment = @insurance.package
      InsuranceService.new(id: shipment.id,
                           courier_for_client: shipment.courier_for_client,
                           insurance: @insurance,
                           company: shipment.company,
                           automatization: @automatization).active
      respond_with(@insurance)
    end
  rescue => e
    render_rescue(e)
  end

  def destroy
    Insurance.transaction do
      raise unless @insurance.update(insurance_params)

      respond_with(@insurance)
    end
  rescue => e
    render_rescue(e)
  end

  private

  def set_company
    @company = company
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def set_insurance
    @insurance = @company.insurances.find_by(id: params[:id])
    raise 'Dirección no encontrado' unless @insurance.present?
  rescue => e
    render_rescue(e)
  end

  def set_insurances
    @insurances = @company.insurances
  rescue => e
    render_rescue(e)
  end

  def set_automatization
    @automatization = Setting.automatization(company.id).configuration['automatizations']['insurance']
  end

  def insurance_params
    params.require(:insurance).permit(Insurance.allowed_attributes)
  end

  def insurance_edit_params
    params.require(:insurance).permit(Insurance.allowed_edit_attributes)
  end
end
