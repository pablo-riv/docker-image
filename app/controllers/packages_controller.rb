class PackagesController < ApplicationController
  before_action :set_company
  before_action :set_package, only: %i[show find edit update destroy]
  before_action :set_service, only: %i[create new show massive_packages_create edit]
  before_action :prepare_params, only: %i[index download]
  before_action :prepare_date_params, only: %i[index download]
  before_action :set_packages, only: %i[index download]
  before_action :set_start_date, only: %i[monitor]
  before_action :set_with_series, only: %i[index download]
  before_action :set_communes, only: %i[edit]
  before_action :set_email, only: %i[download]

  def index; end

  def new
    @package = @company.packages.new
  end

  def edit; end

  def update
    unless @package.editable_by_client
      flash[:danger] = 'No es posible editar el pedido'
      return redirect_to package_path(@package)
    end
    exec_alert = need_alert_notification?
    Package.transaction do
      if @package.update(edit_package_params)
        @package.new_tracking
        Notifications::BuyerNotificationService.dispatch(@package) if exec_alert
        flash[:success] = 'Envío editado correctamente'
        redirect_to packages_path
      else
        @package.errors.add :reference
        flash[:danger] = @package.errors.full_messages.join('. ')
        redirect_to edit_package_path(@package)
      end
    end
  end

  def destroy
    unless @package.archivable_by_client
      flash[:danger] = 'No es posible eliminar el pedido'
      redirect_to package_path(@package)
    end
    if @package.archive
      PickupService.archive_items(items: params[:id])
      flash[:success] = 'Envío eliminado correctamente'
      redirect_to packages_path
    else
      flash[:alert] = @package.errors.full_messages.join('. ')
      render :edit
    end
  rescue StandardError => e
    flash[:alert] = e.message
    redirect_to packages_path
  end

  def massive
    unless current_account.current_company.fulfillment?
      flash[:danger] = 'Página no disponible.'
      redirect_to(packages_path)
    end
  end

  def create
    Package.transaction do
      @package = Package.massive_create(packages: [package_params], account: current_account, branch_office: @company.default_branch_office, fulfillment: @setting_fulfillment, opit: @opit)
      raise @package if @package.is_a?(String)
    end

    render json: { state: :ok, package: @package }, status: :ok
  rescue StandardError => e
    Rails.logger.debug { e.message.red }
    flash[:danger] = e.class == RuntimeError ? e.message : 'Favor ingresar todos los datos.'
    render json: { state: :error }, status: :bad_request
  end

  def massive_packages_create
    params[:packages] = params[:packages].map! { |package| package.permit(Package.allowed_attributes) }
    @packages = Package.massive_create(packages: params[:packages], account: current_account, branch_office: @company.default_branch_office, fulfillment: @setting_fulfillment, opit: @opit)
    raise @packages if @packages.is_a?(String)

    render json: { state: :ok, message: 'Envíos creados exitosamente' }, status: :ok
  rescue StandardError => e
    Rails.logger.debug { "#{e} --- #{e.message}\n#{e.backtrace[0]}".red.swap }
    flash[:danger] = e.class == RuntimeError ? e.message : 'Favor ingresar todos los datos.'
    render json: { state: :error }, status: :bad_request
  end

  def find_sku
    sku = FulfillmentService.sku(params[:id])
    render json: { amount: sku['amount'], description: sku['description'], min_amount: sku['min_amount'] }, status: :ok
  end

  def show
    redirect_to(packages_path) if @package.nil?
    @orders =
      (FulfillmentService.order_skus(@package.id) if @setting_fulfillment.present?)
    puts "😎\t #{@orders.to_json}".yellow
  rescue StandardError => e
    Rails.logger.debug { e.message.red }
    @orders = []
  end

  def find
    render json: { state: :ok, package: @package.serialize_address }, status: :ok
  rescue StandardError => e
    render json: { state: :ok, package: {}, message: e.message }, status: :bad_request
  end

  def filter_communes
    @communes = Region.find_by(name: params[:region_name]).communes
  rescue StandardError => e
    puts e.message.to_s.red
    @communes = Commune.all
  ensure
    render json: @communes, status: :ok
  end

  def download
    MassiveDownloadJob.perform_later(from: @from_date.to_date.strftime('%d-%m-%Y'),
                                     to: @to_date.to_date.strftime('%d-%m-%Y'),
                                     company: @company,
                                     with_series: @with_series,
                                     email: @email_to,
                                     params: params.to_h)
    flash[:success] = 'Tu descarga ha iniciado y será enviada a tu correo en unos minutos'
    redirect_back(fallback_location: :index)
  end

  def monitor
    @packages = @company.packages.calendar_packages(params)
  end

  def by_references
    packages = Package.left_outer_joins(:address, address: :commune, commune: :region)
                      .with_tracking.with_courier.where(reference: params[:references], branch_office_id: @company.branch_offices.ids, created_at: 10.business_days.before(Date.current)..Date.current.at_end_of_day)
                      .select(:id, :reference, :full_name, :courier_for_client, :created_at, :sub_status)
                      .order("ARRAY_POSITION(ARRAY[#{"'#{params[:references].join("','")}'"}]::varchar[], packages.reference)").load
    render json: { state: :ok, packages: packages }, status: :ok
  rescue StandardError => e
    render json: { state: :ok, packages: [], message: e.message }, status: :bad_request
  end

  private

  def set_start_date
    params[:start_date] ||= Date.current
  end

  def skus_by_client
    @sku_client = FulfillmentService.by_client(@company.id)
  end

  def set_package
    @package = @company.packages.includes(:commune, :address).find_by(id: params[:id]) if params[:id]
    raise 'Sin Package' if @package.nil?
  rescue StandardError => e
    flash[:danger] = 'Package buscado no existe.'
    puts e.message.to_s.red
    redirect_back(fallback_location: { action: :index })
  end

  def prepare_date_params
    @from_date = params[:from_date] || (Date.current - 7.day).strftime('%d/%m/%Y')
    @to_date = params[:to_date] || Date.current.strftime('%d/%m/%Y')
    @date_interval = { from: Date.parse(@from_date), to: Date.parse(@to_date) }
    @elastic_date_interval = { from: Time.parse(@from_date).strftime('%Y-%m-%dT00:00:00%z'), to: Time.parse(@to_date).strftime('%Y-%m-%dT23:59:59%z') }
  end

  def set_packages
    return if @with_series && params[:action] == 'download'

    @packages =
      if params[:q].present?
        @company.packages.searching(current_account, params[:q], params[:page])
      elsif params[:filter]
        @company.packages.dashboard_filter(params[:filter])
      elsif params[:from_calendar]
        base = @company.packages.dump_between_dates(@date_interval)
        asking_params = {}
        iterable_params = params.slice('by_status', 'from_courier', 'returned', 'payable', 'from_service').each { |k, v| asking_params[k] = v unless v.blank? }
        base = iterable_params.blank? ? base : @company.packages.filterable_with_base(base, asking_params)
        (params[:from_calendar] ? base.reject(&:statuses_condition) : base).sort_by(&:id).reverse
      else
        SearchService::Package.new(from_date: @date_interval[:from], to_date: @date_interval[:to], status: params[:by_status], payables: params[:payable], returned: params[:returned], courier: params[:from_courier], branch_offices: @company.branch_offices.ids).search
      end

    @packages_csv = @packages
    @packages = Kaminari.paginate_array(@packages).page(params[:page]).per(50)
  end

  def set_communes
    @communes = Commune.all
  end

  def set_service
    @setting_fulfillment = Setting.fulfillment(@company.id)
    @setting_notification = Setting.notification(@company.id)
    @opit = Setting.opit(@company.id)
  end

  def set_company
    @company = current_account.current_company
  end

  def prepare_params
    @from_date = params[:from_date] || (Date.current - 7.day).strftime('%d/%m/%Y')
    @to_date = params[:to_date] || Date.current.strftime('%d/%m/%Y')
    @status = params[:by_status]
    @courier = params[:from_courier]
  end

  def package_params
    params.require(:package).permit(Package.allowed_attributes)
  end

  def edit_package_params
    params.require(:package).permit(Package.edited_attributes)
  end

  def set_with_series
    @with_series = !params[:with_series].blank? && params[:with_series].to_s == 'true'
  end

  def set_email
    @email_to = params[:email_to].presence || current_account.email
  end

  def need_alert_notification?
    !@package.tracking_number.present? && @package.is_payable && package_params[:tracking_number].present?
  end
end
