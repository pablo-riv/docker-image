class V::V4::AccountsController < V::ApplicationController
  before_action :set_accounts, only: %[index]
  before_action :set_companies, only: %[index]

  def index
    @all = @accounts.as_json(only: [:email])
    @total = @all.size
    @accounts =
      if params[:email].present?
        @accounts.where(email: params[:email])
      else
        @accounts.page(params[:page]).per(params[:per])
      end
    respond_with(@accounts, @total, @companies)
  end

  def show
    @account = current_account
    respond_with(@account)
  end

  def disable_suite
    company = current_account.current_company
    company.update(platform_version: 2, suite_disable_count: company.suite_disable_count + 1)

    render json: { state: :ok }, status: :ok
  end

  private

  def set_accounts
    @accounts = Account.joins('INNER JOIN entities e ON e.id = accounts.entity_id')
                       .joins('INNER JOIN people p on accounts.person_id = p.id')
                       .joins("INNER JOIN companies c on c.id = e.actable_id AND LOWER(e.actable_type) = 'company'")
                       .where('c.platform_version = 3').where.not(id: 1).with_role(:owner)
                       .select_hack_data.distinct('accounts.id').load
  end

  def set_companies
    @companies = Company.joins("INNER JOIN entities e ON e.actable_id = companies.id AND LOWER(e.actable_type) = 'company'")
                        .where(platform_version: 3).where.not('companies.id = 1').select('companies.id as id, e.name as name, companies.created_at, companies.updated_at').load
  end
end
