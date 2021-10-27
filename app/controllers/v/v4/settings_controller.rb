class V::V4::SettingsController < V::ApplicationController
  before_action :set_company
  before_action :set_service, only: [:show]
  before_action :set_setting, only: [:show]
  before_action :set_settings, only: [:index]
  before_action :set_automatizations, only: [:automatizations]

  def index
    respond_with(@settings)
  end

  def show
    respond_with(@setting)
  end

  def automatizations
    @setting.update_columns(configuration: params[:configuration])
    render json: { state: :ok, message: 'Actualización correcta' }, status: :ok
  rescue StandardError => e
    render_rescue(e)
  end

  private

  def set_company
    @company = company
  end

  def set_settings
    @settings = company.settings
  rescue => e
    render_rescue(e)
  end

  def set_setting
    @setting = company.settings.find_by(service_id: @service.id)
    raise 'Servicio no encontrado' unless @service.present?
  rescue => e
    render_rescue(e)
  end

  def set_service
    @service = Service.find_by(id: params[:service_id])
    raise 'Servicio no encontrado' unless @service.present?
  rescue => e
    render_rescue(e)
  end

  def set_automatizations
    raise 'Actualización no permitida' unless params[:service_id] == 9

    @setting = company.settings.find_by(service_id: params[:service_id])
    raise 'Servicio no encontrado' unless @setting.present?
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
