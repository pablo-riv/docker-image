class V::V4::Setups::CommercialController < V::ApplicationController
  before_action :set_company
  before_action :set_account, only: %i[show update]

  def show
    respond_with(@contact)
  rescue => e
    render_rescue(e)
  end

  def create
    temp_password = generate_random_password
    @account = @company.acting_as.accounts.create(commercial_params.merge('password' => temp_password, 'password_confirmation' => temp_password))
    @account.add_role(:commercial)

    respond_with(@account)
  rescue => e
    render_rescue(e)
  end

  def update
    @account.update_columns(email: commercial_params[:email])
    @account.person.update(commercial_params[:person_attributes].to_h)
    @account.add_role(:commercial) unless @account.has_role?(:commercial)
    @company.acting_as.update_columns(website: params[:commercial][:company][:website],
                                      name: params[:commercial][:company][:name])
    @company.update_columns(sales_channel: params[:commercial][:company][:sales_channel].to_hash,
                            commercial_flow: DateTime.current.to_s)
    render json: { message: 'Datos almacenados', account: @account }, status: :ok
  rescue => e
    render_rescue(e)
  end

  private

  def set_account
    @account = @company.accounts.find { |account| account.has_role?(:commercial) }
  end

  def set_company
    @company = company
  end

  def commercial_params
    params.require(:commercial).permit(Account.allowed_attributes)
  end

  def render_rescue(exception)
    Rails.logger.info { "#{exception.message}\n#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def generate_random_password
    10.times.map { rand(0..9) }.join('')
  end
end
