class V::V2::SkusController < V::ApplicationController
  before_action :set_company, only: [:index, :create]
  before_action :set_skus, only: [:index, :by_client]

  def index
    render json: @skus, status: :ok
  rescue StandardError => e
    render_rescue(e)
  end

  def show
    @sku = FulfillmentService.sku_by_client(company.id, params[:id])
    if @sku.blank?
      render json: { status: :error, message: 'No se encontraron datos' }, status: :bad_request
    else
      render json: @sku, status: :ok
    end
  end

  def by_name
    @sku = FulfillmentService.sku_by_name(params[:name])
    if @sku.blank?
      render json: { status: :error, message: 'No se encontraron datos' }, status: :bad_request
    else
      render json: @sku, status: :ok
    end
  end

  def create
  end

  def by_client
    if @skus.blank?
      render json: { status: :error, message: 'No se encontraron datos' }, status: :bad_request
    else
      render json: @skus, status: :ok
    end
  end

  def new_series_out
    series = FulfillmentService.new_series_out(JSON.parse(params.merge(from: 'alert').to_json))
    raise unless FulfillmentService.compraqui_package?(params)
    raise if series.blank? || series.to_s.include?('error')

    render json: { status: 'success', response: series }, status: :ok
  rescue StandardError => e
    puts e.message
    # render json: { status: 'failure', response: params[:listaLpnDestino], message: 'Ocurrió un problema al registrar el movimiento del serie' }, status: :bad_request
    render json: {
      "status": 'success',
      "response": params['listaLpnDestino'].map do |lpns|
        {
          "ordendesalida": lpns['ordendesalida'],
          "status": 'success',
          "message": 'Sku registrado'
        }
      end
    }
  end

  private

  def set_company
    @company = company
  end

  def set_skus
    @skus = FulfillmentService.by_client(company.id)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
