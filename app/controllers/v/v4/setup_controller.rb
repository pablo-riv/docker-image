class V::V4::SetupController < V::ApplicationController
  before_action :set_company

  def show
    respond_with(@company)
  end

  # update default branch_office data
  def administrative
    raise unless @company.update(administrative_params)

    respond_with(@company)
  rescue => e
    render_rescue(e)
  end

  def operative
    @account = current_account
    raise @account.errors unless @account.person.update(person_operative_params)

    respond_with(@account)
  rescue => e
    render_rescue(e)
  end

  def account
    @account = current_account
    raise @account.errors unless @account.update(account_operative_params)

    respond_with(@account)
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

  def account_operative_params
    params.require(:account).permit(:email, :password, :password_confirmation)
  end

  def person_operative_params
    params.require(:person).permit(:first_name, :last_name, :phone)
  end

  def administrative_params
    params.require(:company).permit(:name, :run, :website, :business_name, :business_turn, :bill_email, :bill_phone, :bill_address, :email_contact)
  end
end
