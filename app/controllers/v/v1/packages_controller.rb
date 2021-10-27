class V::V1::PackagesController < V::ApplicationController
  include Packable

  before_action :set_branch_office, only: [:mass_create]
  before_action :set_service, only: [:mass_create]

  def index
  end

  def mass_create
    return render json: { error: "Account suspended. Please contact your key account manager.", status: 403 } if current_account.current_company.debtors

    Package.transaction do
      branch_office = current_account.has_role?(:owner) ? current_account.entity_specific.default_branch_office : current_account.entity_specific
      packs = PackageService.set_communes(params[:packages])
      @packages = Package.massive_create(packages: packs, account: current_account, branch_office: branch_office, fulfillment: @fulfillment, opit: @opit)
      @packages.is_a?(String) ? (render json: { error: @packages, status: 403 }) : (render template: 'api/packages/create_mass', status: 200)
    end
  end

  private

  def set_branch_office
    @branch_office = branch_office
  end

  def set_service
    @fulfillment = Setting.fulfillment(@branch_office.company_id) if current_account.has_role?(:owner)
    @opit = Setting.opit(@branch_office.company_id)
  end
end
