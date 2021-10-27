class V::V4::PickupsController < V::ApplicationController
  before_action :set_company, only: %i[index create show]
  before_action :set_branch_office, only: %i[create show]
  before_action :set_dates, only: %i[index]
  before_action :set_pickups, only: %i[index]
  before_action :set_pickup, only: %i[show]
  before_action :set_shipments, only: %i[create]

  def index
    respond_with(@pickups, @total)
  end

  def show
    respond_with(@pickup)
  end

  def create
    raise I18n.t('pickups.messages.errors.shipments_not_found') unless @shipments.present?

    @pickup =
      PickupService.new(packages: @shipments,
                        provider: provider,
                        schedule: schedule,
                        address: branch_office_address,
                        type_of_pickup: 'daily',
                        status: 0).add_shipments_to_pickup
    render json: { state: :ok, pickup: @pickup, message: 'Retiro creado correctamente' }, status: :ok
  rescue StandardError => e
    render_rescue(e)
  end

  private

  def set_company
    @company = current_account.current_company
  end

  def set_branch_office
    @branch_office = @company.default_branch_office
  end

  def set_pickup
    @pickup = @company.pickups.find_by(id: params[:id])
    raise 'Envío no encontrado' unless @pickup.present?
  rescue => e
    render_rescue(e)
  end

  def set_pickups
    data = SearchService::Pickup.new(from_date: @date[:from],
                                     to_date: @date[:to],
                                     state: params[:state],
                                     id: params[:id],
                                     branch_offices: @company.branch_offices.ids,
                                     per: params[:per],
                                     page: params[:page]).search
    @pickups = data[:pickups]
    @total = data[:total]
  end

  def set_shipments
    @shipments = Package.where(branch_office_id: @company.branch_offices.ids, id: params[:pickup][:package_ids]).where.not(tracking_number: [nil, ''])
  end

  def branch_office_address
    address = @branch_office.full_address
    coords = { lat: address.coords[:latitude], lng: address.coords[:longitude] }
    { place: address, coords: coords }
  end

  def provider
    pickup_params[:provider] || 0
  end

  def schedule
    { date: pickup_params[:schedule], range_time: '14:00 a 17:00', active: true }
  end

  def set_dates
    @from_date = (params[:from_date].present? ? Date.parse(params[:from_date]) : (Date.current - 1.month)).strftime('%d/%m/%Y')
    @to_date = (params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current).strftime('%d/%m/%Y')
    @date = { from: @from_date, to: @to_date }
  end

  def pickup_params
    params.require(:pickup).permit(Pickup.allowed_attributes)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
