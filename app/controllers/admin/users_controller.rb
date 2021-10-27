class Admin::UsersController < ApplicationController
  before_action :set_accounts

  def index
    redirect_to root_path unless current_account.email == "staff@shipit.cl"
  end

  private

  def set_accounts
    @all = Account.order(:created_at)
    @accounts = params[:id].present? ? @all.where(id: params[:id]) : @all
    @accounts = @accounts.page(params[:page]).per(100)
  end
end
