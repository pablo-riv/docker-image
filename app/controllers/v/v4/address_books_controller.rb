class V::V4::AddressBooksController < V::ApplicationController
  before_action :set_company
  before_action :set_address_book, only: %i(show update destroy)
  before_action :set_address_books, only: %i(index)

  def index
    respond_with(@address_books)
  end

  def show
    respond_with(@address_book)
  end

  def create
    AddressBook.transaction do
      book = eval(address_book_params[:addressable_type]).create(name: params[:address_book][:name],
                                                                 address_book_attributes: address_book_params)
      raise unless book.persisted?

      @address_book = book.address_book
      respond_with(@address_book)
    end
  rescue => e
    render_rescue(e)
  end

  def update
    AddressBook.transaction do
      raise unless @address_book.update(address_book_params) && @address_book.addressable.update(name: params[:address_book][:name])

      respond_with(@address_book)
    end
  rescue => e
    render_rescue(e)
  end

  def destroy
    AddressBook.transaction do
      raise unless @address_book.update(archive: true)

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

  def set_address_book
    @address_book = @company.address_books.find_by(id: params[:id])
    raise 'Dirección no encontrado' unless @address_book.present?
  rescue => e
    render_rescue(e)
  end

  def set_address_books
    @address_books = @company.address_books
  rescue => e
    render_rescue(e)
  end

  def address_book_params
    params.require(:address_book).permit(AddressBook.allowed_attributes)
  end
end
