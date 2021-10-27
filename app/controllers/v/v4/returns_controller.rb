class V::V4::ReturnsController < V::ApplicationController
  before_action :set_company
  before_action :set_return, only: %i(show update destroy)
  before_action :set_returns, only: %i(index)

  def index
    render json: { returns: @returns }, status: :ok
  end

  def show
    render json: { return: @return }, status: :ok
  end

  def create
    Return.transaction do
      @return = Return.new(return_params)
      @return.address_book.assign_attributes(company_id: @company.id)
      raise unless @return.save

      render json: { return: @return }, status: :ok
    end
  rescue => e
    render_rescue(e)
  end

  def update
    Return.transaction do
      raise unless @return.update(return_params)

      render json: { return: @return }, status: :ok
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

  def set_return
    @return = @company.returns.joins(:address_book).find_by(id: params[:id])
    raise 'Dirección de devolución no disponible' unless @return.present?
  rescue => e
    render_rescue(e)
  end

  def set_returns
    @returns = @company.returns.joins(:address_book)
    raise 'Sin dirección de devolución disponibles' unless @returns.present?
  rescue => e
    render_rescue(e)
  end

  def return_params
    params.require(:return).permit(Return.allowed_attributes)
  end
end