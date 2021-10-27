class V::V4::Setups::OperativeController < V::ApplicationController
  before_action :set_company
  before_action :set_contact, only: %i[show update]
  before_action :create_contact, only: %i[create]
  before_action :create_or_update_origin, only: %i[create update]
  before_action :create_return, only: %i[create]

  def show
    respond_with(@contact)
  rescue => e
    render_rescue(e)
  end

  def create
    @company.update_columns(operative_flow: DateTime.current.to_s)
    render json: { message: 'Datos almacenados', contact: @contact }, status: :ok
  rescue => e
    render_rescue(e)
  end

  def update
    @contact.update(operative_params)

    respond_with(@contact)
  rescue => e
    render_rescue(e)
  end

  private

  def create_contact
    @contact = @company.contacts.create(email: operative_params[:email],
                                        first_name: operative_params[:person_attributes][:first_name],
                                        last_name: operative_params[:person_attributes][:last_name],
                                        phone: operative_params[:person_attributes][:phone],
                                        role_name: 'operative')
  end

  def create_or_update_origin
    @origin =
      if @company.origins.size.zero?
        origin = @company.origins.new(
          name: 'default',
          address_book_attributes: {
            company_id: @company.id,
            full_name: @contact.full_name,
            phone: @contact.phone,
            email: @contact.email,
            default: true,
            address_attributes: JSON.parse(params[:origin].to_json)
          },
          branch_office_id: @company.default_branch_office.id)
        raise origin.errors unless origin.save

        origin
      else
        origin = @company.origins.joins(:address_book).find_by(address_books: { default: true })
        origin.address_book.address.update_columns(JSON.parse(params[:origin].to_json)) if params[:origin].present?
        origin
      end
  end

  def create_return
    @return = @company.returns.new(
      name: 'default',
      address_book_attributes: {
        company_id: @company.id,
        full_name: @contact.full_name,
        phone: @contact.phone,
        email: @contact.email,
        default: true,
        address_attributes: JSON.parse(params[:return].to_json)
      }
    )
    raise @return.errors unless @return.save
  end

  def set_contact
    @contact = @company.contacts.find { |account| account.role_name == 'operative' }
  end

  def set_company
    @company = company
  end

  def operative_params
    params.require(:operative).permit(Account.allowed_attributes)
  end

  def render_rescue(exception)
    Rails.logger.info { "#{exception.message}\n#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def generate_random_password
    10.times.map { rand(0..9) }.join('')
  end
end
