class V::V2::SettingsController < V::ApplicationController
  before_action :set_setting, only: [:index, :show, :update]
  before_action :set_service, only: [:show]

  def index
    render json: @setting, status: :ok
  end

  def show
    if @setting.service_id == 3
      render json: { configuration: @setting.configuration}
    else
      render json: { error: 'No tienes privilegios para visualizar esta información' }
    end
  end

  def update
    @setting.update_columns(configuration: JSON.parse(params[:configuration].to_json))
    render json: { state: :ok, configuration: @setting.configuration }, status: :ok
  rescue StandardError => e
    render json: { state: :error, error: e.message }, status: :bad_request
  end

  private

  def setting_params
    params.require(:setting).permit(Setting.allowed_attributes)
  end

  def set_service
    @service = params[:service_id]
  end

  def set_setting
    company = current_account.entity.specific.id
    @setting = Setting.by_company(company).where(service_id: 3).first
  end
end
