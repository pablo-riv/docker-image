class V::SessionsController < Devise::SessionsController
  acts_as_token_authentication_handler_for Account, fallback_to_devise: false
  skip_before_action :verify_authenticity_token

  before_action :filter_format, only: %i(create destroy)
  before_action :validate, only: %i(create)
  before_action :set_account, only: %i(create)

  def create
    return account_not_found if @account.nil?

    if @account.valid_password?(params[:account][:password])
      @account.update_columns(suite_sessions: (@account.suite_sessions + 1))
      render 'v/v4/accounts/login.json', status: :ok
    else
      render status: :unauthorized, json: { message: I18n.t('devise.failure.invalid') }
    end
  end

  def destroy
    @account = Account.find_by(authentication_token: params[:authentication_token])
    if @account.nil?
      render status: :not_found, json: { message: I18n.t('devise.failure.invalid_token') }
    else
      sign_out(@account)
      render status: :ok, json: { message: 'Has salido de shipit...', session: nil,  }
    end
  rescue => e
    render status: :bad_request, json: { message: e.message }
  end

  private

  def account_not_found
    render status: :unauthorized, json: { message: I18n.t('devise.failure.invalid') }
  end

  def set_account
    @account = Account.find_by(email: params[:account][:email])
  end

  def filter_format
    if request.format != :json
      render status: :not_acceptable, json: { message: 'The request must be JSON.' }
      return
    end
  end

  def validate
    if params[:account][:email].nil? || params[:account][:password].nil?
      render status: :bad_request, json: { message: 'The request MUST contain the account email and password.' }
      return
    end
  end
end
