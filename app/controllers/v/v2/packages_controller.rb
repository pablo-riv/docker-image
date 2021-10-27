class V::V2::PackagesController < V::ApplicationController
  include Packable
  before_action :set_date, only: %i[index]
  before_action :set_company, only: %i[index create mass_create filter]
  before_action :set_branch_office, only: %i[show destroy create update package_by_reference mass_create]
  before_action :set_package, only: %i[show update destroy]
  before_action :set_service, only: %i[mass_create create]
  before_action :set_packages, only: :package_by_reference

  api :GET, '/packages', 'This will show all packages of the company'
  def index
    per = params[:per].present? ? params[:per].try(:to_i) : 50
    page = params[:page].present? ? params[:page].try(:to_i) : 1
    @total = @company.packages.by_date(@date.year, @date.month).load
    @packages = Kaminari.paginate_array(@total).page(page < 1 ? 1 : page).per(per > 250 ? 250 : per)
    if @packages.nil?
      render json: { error: 'No tienes packages disponibles' }, status: :bad_request
    else
      @total = @total.size
      respond_with(@packages)
    end
  rescue StandardError => e
    render_rescue(e)
  end

  api :GET, '/packages/filter', 'Filter packages by specific parameters'
  def filter
    branch_offices = @company.branch_offices.ids.include?(params[:branch_office_id]) ? params[:branch_office_id] : @company.branch_offices.ids
    data = SearchService::Package.new(from_date: params[:from_date],
                                      to_date: params[:to_date],
                                      state: params[:status],
                                      page: params[:page],
                                      per: params[:per],
                                      courier: params[:courier],
                                      branch_offices: branch_offices,
                                      sorter: params[:sorter],
                                      sorter_by: params[:sorter_by]).filter
    @packages = data[:packages]
    @total = data[:total]
    raise data[:error] if data[:error].present?
    render :index
  rescue StandardError => e
    render_rescue(e)
  end

  api :GET, '/packages/:id', 'This will show a single package filtered by id'
  param :id, :number
  def show
    if @package.nil?
      render json: { error: 'No se encontro el package solicitado' }, status: :bad_request
    else
      respond_with(@package)
    end
  end

  def package_by_reference
    raise unless @packages.any?

    @total = @packages.count
    render :index
  rescue => e
    render json: { error: 'No se encontró el package solicitado' }, status: :bad_request
  end

  api :POST, '/packages', 'Here is where you can send packages to create'
  param_group :pack, Packable
  def create
    Package.transaction do
      raise 'Account suspended. Please contact your key account manager.' if @company.debtors

      packs = PackageService.set_communes([package_params])
      @package = Package.massive_create(packages: packs,
                                        account: current_account,
                                        branch_office: @branch_office,
                                        fulfillment: @fulfillment,
                                        opit: @opit)
      raise @package if @package.present? && @package.is_a?(String)

      @package = @package.first
      respond_with(@package)
    end
  rescue => e
    Rails.logger.info { "ERROR #{e.message}\nBUGTRACE: #{e.backtrace.join("\n")}".red.swap }
    render json: { message: e.message, state: :error }, status: :bad_request
  end

  api :POST, '/integration', 'Here is where you can send packages to create'
  param_group :pack, Packable
  def integration
    branch_office = current_account.has_role?(:owner) ? current_account.entity_specific.default_branch_office : current_account.entity_specific
    oss = OrderService.invert_package_to_order(branch_office, package_params)
    render json: { orders: oss }, status: :ok
  rescue StandardError => e
    puts "#{e.message} \n #{e.backtrace.first(5).join("\n")}".red
    render json: { error: e.message }, status: :bad_request
  end

  api :PATCH, '/packages/:id', 'Here is allowed to update a packgage info'
  param_group :pack, Packable
  def update
    raise 'No es posible editar el pedido' unless @package.editable_by_client

    if @package.update(package_params)
      @package.dispatch_webhook
      respond_with(@package)
    else
      render json: { error: @package.errors.to_s }, status: :bad_request
    end
  rescue => e
    render json: { message: e.message, state: :error }, status: :bad_request
  end

  api :DELETE, '/packages/:id', 'Here is where you can delete package'
  param :id, :number
  def destroy
    if @package.nil?
      render json: { error: 'No se encontro el package solicitado' }, status: :bad_request
    else
      @package.update_columns(is_archive: true)
      @package.dispatch_webhook
      Opit.new(@package, false).remove_shippify_tracking if @package.courier_for_client == 'shippify'
      respond_with(@package)
    end
  end

  api :POST, '/packages/mass_create', 'Here is where can be send a group of packages to create at time'
  param :packages, Array do
    param_group :pack, Packable
  end
  def mass_create
    packages = PackageService.set_communes(params[:packages])
    PackageMassiveJob.perform_now(packages: packages,
                                  account: current_account,
                                  branch_office: @branch_office,
                                  fulfillment: @fulfillment,
                                  opit: @opit)
    render json: { message: 'Se esta procesando la información' }, status: :ok
  rescue => e
    Rails.logger.info { "ERROR #{e.message}\nBUGTRACE: #{e.backtrace[0]}".red.swap }
    # OrderMailer.warn_about_failure(current_account, branch_office).deliver
    Publisher.publish('status_log', message: "client: branch_office #{branch_office.id} #{e.message}")
    render json: { message: e.message, state: :error }, status: :bad_request
  end

  def backup
    if params[:packages].nil?
      render json: { message: 'No has enviado packages.' }, status: :bad_request
    else
      MassiveBackupJob.perform_now(packages_params, current_account, @fulfillment)
      render json: { message: 'Se esta procesando la información' }, status: :ok
    end
  end

  private

  def set_branch_office
    @branch_office = branch_office
  end

  def set_company
    @company = company
    raise 'Cliente no encontrado' unless @company.present?
  rescue StandardError => e
    render_rescue(e)
  end

  def set_service
    @fulfillment = current_account.entity_specific.services.find_by(id: 4) if current_account.has_role?(:owner)
    @integration = Setting.fullit(@company.id).seller_configuration('jumpseller')
    @opit = Setting.opit(@company.id)
  end

  def set_package
    @package = Package.unscoped.find_by(branch_office_id: @branch_office.id, id: (params[:package_id] || params[:id]))
  rescue StandardError => e
    render json: { message: e.message.to_s }, status: :bad_request
  end

  def set_packages
    @packages = Package.unscoped.where(branch_office: @branch_office.id, reference: params[:reference])
  end

  def set_date
    year = (2015..Date.current.year).cover?(params[:year].try(:to_i)) ? params[:year].try(:to_i) : Date.current.year
    month = (1..12).cover?(params[:month].try(:to_i)) ? params[:month].try(:to_i) : Date.current.month
    @date = Date.new(year, month)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def package_params
    params.require(:package).permit(Package.allowed_attributes)
  end

  def packages_params
    params.require(:packages).map { |package| package.permit(Package.allowed_attributes) }
  end
end
