class V::V4::DestiniesController < V::ApplicationController
  before_action :set_company
  before_action :set_destiny, only: %i(show update destroy)
  before_action :set_destinies, only: %i(index)

  def index
    respond_with(@destinies)
  end

  def show
    respond_with(@destiny)
  end

  def create
    @destiny = Destiny.new(destiny_params)
    @destiny.address_book.assign_attributes(company_id: @company.id)
    Destiny.transaction do
      raise unless @destiny.save

      respond_with(@destiny)
    end
  rescue => e
    render_rescue(e)
  end

  def update
    Destiny.transaction do
      raise unless @destiny.update(destiny_params)

      respond_with(@destiny)
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

  def set_destiny
    @destiny = Destiny.joins(:address_book).find_by(id: params[:id], address_books: { company_id: @company.id })
    raise 'Destino no encontrado' unless @destiny.present?
  rescue => e
    render_rescue(e)
  end

  def set_destinies
    @destinies = Destiny.joins(:address_book).where(address_books: { company_id: @company.id })
    raise 'Sin destinos disponibles' unless @destinies.present?
  rescue => e
    render json: { destinies: [], message: e.message, bug_trace: e.backtrace }, status: :ok
  end

  def destiny_params
    params.require(:destiny).permit(Destiny.allowed_attributes)
  end
end
