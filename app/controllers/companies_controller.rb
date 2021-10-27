class CompaniesController < ApplicationController
  before_action :set_company, only: %i[edit update update_preference]

  def edit
    @company
  end

  def update
    if @company.update(company_params)
      redirect_to dashboard_path
    else
      redirect_back(fallback_location: { action: :edit })
    end
  rescue => e
    puts e.message.to_s.red
    redirect_back(fallback_location: { action: :edit })
  end

  def update_preference
    if @company.update_preference(params[:company])
      render json: { company: @company, logo: @company.logo.url(:small) }, status: :ok
    else
      render json: { company: @company, logo: @company.logo.url(:small) }, status: :error
    end
  end

  def query
    if params[:s].blank?
      redirect_to dashboard_path
    else
      company_branch_offices_ids = current_account.entity_specific.branch_offices.pluck(:id)
      results = Package.searching(current_account, params[:s][:q])
      ids = results.pluck('id')
      @packages = Package.where(id: ids)
    end
  end

  private

  def set_company
    @company = current_account.entity_specific
  rescue => e
    puts e.message.to_s.red
  end

  def company_params
    params.require(:company).permit(Company.allowed_attributes)
  end
end
