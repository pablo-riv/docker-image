class BranchOfficesController < ApplicationController
  before_action :set_branch_office, only: [:edit, :update, :destroy]
  before_action :set_company, only: [:new, :edit, :update]

  def index
    redirect_to dashboard_path if current_account.current_company.fulfillment?
  end

  def all
    @branch_offices = current_account.entity_specific.branch_offices.serialize_data!.sort_by { |br| br['name'].to_s }
    raise 'Sin Información' if @branch_offices.nil?
    render json: { state: :ok, branch_offices: @branch_offices }, status: :ok
  rescue => e
    puts e.message.to_s.red
    render json: { state: :error }, status: :bad_request
  end

  def create
    BranchOffice.transaction do
      raise 'No se completo la transacción' unless BranchOffice.build_branch_office_account(params[:branch_office], current_account.entity_specific)
      render json: { state: :ok, branch_offices: current_account.entity_specific.branch_offices }, status: :ok
    end
  rescue => e
    puts e.message.to_s.red
    render json: { state: :error }, status: :bad_request
  end

  def edit
    @branch_office
  end

  def update
    BranchOffice.transaction do
      raise 'No se completo la transacción' unless BranchOffice.build_branch_office_account(params[:branch_office], current_account.entity_specific, 'edit')
      render json: { state: :ok, branch_offices: current_account.entity_specific.branch_offices.serialize_data! }, status: :ok
    end
  rescue => e
    puts e.message.to_s.red
    render json: { state: :error }, status: :bad_request
  end

  def destroy; end

  def communes
    @communes = Commune.by_type(params[:type]).order_by_name
    raise 'Sin Información' if @communes.nil?

    render json: { state: :ok, communes: @communes }, status: :ok
  rescue => e
    puts e.message.to_s.red
    render json: { state: :error }, status: :bad_request
  end

  def marketplace_request
    BranchOffice.transaction do
      raise 'No se completo la transacción' unless BranchOffice.marketplace_request(current_account, params[:request])
      render json: { state: :ok }, status: :ok
    end
  rescue => e
    puts e.message.red
    render json: { state: :error }, status: :bad_request
  end

  private

  def branch_office_params
    params.require(:branch_office).permit(BranchOffice.allowed_attributes)
  end

  def set_company
    @company = current_account.entity_specific
  rescue => e
    puts e.message.to_s.red
    redirect_back(fallback_location: { action: :index })
  end

  def set_branch_office
    @branch_office = BranchOffice.find(params[:id]) if params[:id]
  rescue => e
    puts e.message.to_s.red
    redirect_back(fallback_location: { action: :index })
  end
end
