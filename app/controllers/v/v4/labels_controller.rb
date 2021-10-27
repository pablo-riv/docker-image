class V::V4::LabelsController < V::ApplicationController
  before_action :set_company
  before_action :set_label_setting, only: %i[update show]

  def show
    respond_with(@label)
  end

  def update
    raise 'No se pudo actualizar la configuracion' unless @label.configuration['printers'].merge!(label_params)
    raise unless @label.update_columns(configuration: @label.configuration)

    respond_with(@label)
  rescue => e
    render_rescue(e)
  end

  private

  def set_company
    @company = company
  end

  def set_label_setting
    @label = Setting.printers(company.id)
    raise 'Servicio no encontrado' unless @label.present?
  rescue => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def label_params
    params.require(:label).permit(:label_package_size)
  end
end
