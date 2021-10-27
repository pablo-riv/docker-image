class V::V4::OriginsController < V::ApplicationController
  before_action :set_company
  before_action :set_origin, only: %i(show update destroy)
  before_action :set_origins, only: %i(index)

  def index
    respond_with(@origins)
  end

  def show
    respond_with(@origin)
  end

  def create
    Origin.transaction do
      @origin = Origin.new(origin_params)
      @origin.address_book.assign_attributes(company_id: @company.id)
      raise unless @origin.save

      respond_with(@origin)
    end
  rescue => e
    render_rescue(e)
  end

  def update
    Origin.transaction do
      raise unless @origin.update(origin_params)

      respond_with(@origin)
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

  def set_origin
    @origin = @company.origins.joins(:address_book).find_by(id: params[:id])
    raise 'Origen no disponible' unless @origin.present?
  rescue => e
    render_rescue(e)
  end

  def set_origins
    @origins = @company.origins.joins(:address_book)
    raise 'Sin origenes disponibles' unless @origins.present?
  rescue => e
    render_rescue(e)
  end

  def origin_params
    params.require(:origin).permit(Origin.allowed_attributes)
  end
end
