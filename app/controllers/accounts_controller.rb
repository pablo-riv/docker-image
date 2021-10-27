class AccountsController < ApplicationController

  before_action :set_company, only: [:new, :create, :index, :edit, :update]
  before_action :set_account, only: [:edit, :update, :show]
  before_action :set_branch_office, only: [:new, :create, :index, :edit, :update]
  before_action :set_type, only: [:index, :new, :create, :edit, :update]

  def index
    @account = current_account.serialize_data!
  end

  def new
    @account = Account.new
    @person = Person.new
  end

  def create
    @account = @type.include?('company') ? @company.acting_as.accounts.build(account_params) : @branch_office.create_account(account_params)
    if @account.generate_relation(account_params[:person_attributes]) && @account.save
      return redirect_to company_branch_office_accounts_path(@company.id, @branch_office.id) if @type.include?('branch_office')
      return redirect_to accounts_path if @type.include?('company')
    else
      flash[:info] = "No se pudo crear la cuenta #{@account.errors}"
      redirect_back(fallback_location: { action: :new })
    end
  end

  def edit
    @person = @account.person
    return @account, @person, @type
  end

  def update
    if @account.update(account_params)
      return redirect_to company_branch_office_accounts_path(@company.id, @branch_office.id) if @type.include?('branch_office')
      return redirect_to accounts_path if @type.include?('company')
    else
      flash[:info] = "No se pudo crear la cuenta #{@account.errors}"
      redirect_back(fallback_location: { action: :new })
    end
  end

  private

  def set_company
    @company = current_account.entity_specific
  rescue => e
    puts e.message.red
    redirect_back(fallback_location: { action: :index })
  end

  def set_account
    @account = @company.accounts.find_by(id: params[:id]) if params[:id]
  rescue => e
    puts e.message.red
    redirect_back(fallback_location: { action: :index })
  end

  def set_branch_office
    @branch_office = BranchOffice.find(params[:branch_office_id]) if params[:branch_office_id]
  end

  def set_type
    @type = Account.validate_account_type_for(@company, @branch_office)
  end

  def account_params
    params.require(:account).permit(Account.allowed_attributes)
  end
end
