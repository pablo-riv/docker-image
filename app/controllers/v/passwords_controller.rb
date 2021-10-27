class V::PasswordsController < Devise::PasswordsController
  skip_before_action :verify_authenticity_token
  before_action :filter_format
  before_action :set_account, only: %i[new create]

  # GET /resource/password/new

  def new
    raise ArgumentError unless @account.present?

    code = @account.send_token_code

    raise unless code.present?

    render json: { code: code, state: :ok }, status: :ok
  rescue ArgumentError => e
    render status: :not_found, json: { message: 'Usuario no encontrado, favor ingresar email existente', state: :error }
  rescue => e
    render status: :bad_request, json: { message: e.message }
  end

  # POST /resource/password
  def create
    raise ArgumentError unless @account.present?
    raise ArgumentError if password_params[:password] != password_params[:password_confirmation]

    @account.assign_attributes(password_params)

    raise ArgumentError unless @account.save(validate: false)

    render json: { account: @account, state: :ok }, status: :ok
  rescue ArgumentError => e
    render status: :not_found, json: { message: 'Usuario no encontrado o passwords no coinciden.', state: :error }
  rescue => e
    render status: :bad_request, json: { message: e.message }
  end

  private

  def set_account
    @account = Account.find_by(email: password_params[:email]) if password_params[:email].present?
  end

  def password_params
    { email: params[:email], password: params[:password], password_confirmation: params[:password_confirmation] }
  end

  def filter_format
    if request.format != :json
      render status: :not_acceptable, json: { message: 'The request must be JSON.' }
      return
    end
  end

  # protected

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
