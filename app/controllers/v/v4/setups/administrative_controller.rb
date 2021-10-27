class V::V4::Setups::AdministrativeController < V::ApplicationController
  before_action :set_company
  before_action :set_contact, only: %i[show update]
  before_action :create_contact, only: %i[create]
  before_action :update_company, only: %i[create]

  def show
    respond_with(@company)
  rescue => e
    render_rescue(e)
  end

  def create
    @company.update_columns(administrative_flow: DateTime.current.to_s)
    render json: { message: 'Datos almacenados', contact: @contact }, status: :ok
  rescue => e
    render_rescue(e)
  end

  def update
    @contact.update(administrative_params)

    respond_with(@contact)
  rescue => e
    render_rescue(e)
  end

  private

  def create_contact
    @contact = @company.contacts.create(email: administrative_params[:email],
                                        first_name: administrative_params[:person_attributes][:first_name],
                                        last_name: administrative_params[:person_attributes][:last_name],
                                        phone: administrative_params[:person_attributes][:phone],
                                        role_name: 'administrative')
  end

  def update_company
    data = JSON.parse(params[:company].to_json)
    @company.update_columns(business_turn: data['business_turn'],
                            business_name: data['business_name'],
                            bill_email: administrative_params[:email],
                            bill_phone: administrative_params[:person_attributes][:phone],
                            bill_address: data['bill_address'])
    @company.acting_as.update_columns(run: data['run'])
  end

  def set_contact
    @contact = @company.contacts.find { |account| account.role_name == 'administrative' }
  end

  def set_company
    @company = company
  end

  def administrative_params
    params.require(:administrative).permit(Account.allowed_attributes)
  end

  def render_rescue(exception)
    Rails.logger.info { "#{exception.message}\n#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def generate_random_password
    10.times.map { rand(0..9) }.join('')
  end
end
