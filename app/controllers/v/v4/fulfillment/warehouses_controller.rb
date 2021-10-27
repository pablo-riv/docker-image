class V::V4::Fulfillment::WarehousesController < V::ApplicationController
  before_action :set_company
  before_action :set_fulfillment
  before_action :set_warehouses, only: %i[index]

  def index
    respond_with(@warehouses)
  end

  private

  def set_company
    @company = company
  end

  def set_fulfillment
    @fulfillment = Setting.fulfillment(@company.id)
    raise 'Cliente sin servicio fulfillment activo' unless @fulfillment.present?
  rescue => e
    render_rescue(e)
  end

  def set_warehouses
    warehouses = FulfillmentService.warehouses
    raise 'No hay bodegas disponibles' unless warehouses.present?

    @warehouses = warehouses.map { |warehouse| warehouse.merge!(address: Address.find_by(id: warehouse['address_id']).try(:serialize_data!)) }
  rescue => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :unprocessable_entity
  end
end
