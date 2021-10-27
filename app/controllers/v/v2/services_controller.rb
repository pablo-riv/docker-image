class V::V2::ServicesController < V::ApplicationController
  before_action :set_service, only: [:show]
  def index
    @services = Service.all
  end

  def show
    if @service.nil?
      render json: { error: "No se encontro el servicio solicitado" }, status: :bad_request
    else
      respond_with(@service)
    end
  end

  private
    def service_params
      params.require(:service).permit(Service.allowed_attributes)
    end

    def set_service
      @account = Service.find(params[:id]) if params[:id]
    rescue Exception => e
      render json: { error: "#{e.message}" }, status: :bad_request
    end

end
