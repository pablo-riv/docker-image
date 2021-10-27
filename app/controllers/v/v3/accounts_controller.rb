class V::V3::AccountsController < V::ApplicationController
  before_action :set_account, only: [:show]

  def show
    respond_with(@account)
  end

  private

  def set_account
    @account = Account.find_by(authentication_token: params[:authentication_token])
  end
end
