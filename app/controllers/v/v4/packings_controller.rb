class V::V4::PackingsController < V::ApplicationController
  before_action :set_company
  before_action :set_packing, only: %i(show update destroy)
  before_action :set_packings, only: %i(index)

  def index
    respond_with(@packings)
  end

  def show
    respond_with(@packing)
  end

  def create
    Packing.transaction do
      @packing = @company.packings.create(packing_params)
      raise unless @packing.persisted?

      respond_with(@packing)
    end
  rescue => e
    render_rescue(e)
  end

  def update
    Packing.transaction do
      raise unless @packing.update(packing_params)

      respond_with(@packing)
    end
  rescue => e
    render_rescue(e)
  end

  def destroy
    Packing.transaction do
      raise unless @packing.update(archive: true)

      render json: { state: :ok }, status: :ok
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

  def set_packing
    @packing = @company.packings.find_by(id: params[:id])
  end

  def set_packings
    @packings = @company.packings
  end

  def packing_params
    params.require(:packing).permit(Packing.allowed_attributes)
  end
end
