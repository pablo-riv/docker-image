class V::V4::PrintersController < V::ApplicationController
  before_action :set_dates, only: %i[index create]
  before_action :set_company
  before_action :set_setting, only: %i[index create]
  before_action :set_shipments, only: %i[index create]
  before_action :set_shipment, only: %i[show]
  before_action :set_references, only: %i[references]

  def index
    @shipments = Kaminari.paginate_array(@shipments).page(params[:page]).per(params[:per])
    respond_with(@shipments, @integrations, @setting, @total_shipments)
  end

  def show
    respond_with(@shipment)
  end

  def create
    raise 'No tienes envíos' if @shipments.blank?

    download = @company.downloads.create(kind: :label, status: :pending) if @setting.printer_way == 'download'

    @link = @setting.print_labels(current_account, download, @shipments)
    @company.prints.create(quantity: @shipments.size)
    respond_with(@link, @shipments)
  rescue RuntimeError => e
    render_rescue(e)
  rescue StandardError => e
    render_rescue(e)
  end

  def references
    respond_with(@shipments, @total_shipments)
  end

  private

  def set_company
    @company = company
  end

  def set_shipments
    raise 'Packages es un parámetro requerido' if action_name == 'create' && params[:packages].nil?
    raise 'Debe indicar los pedidos' if action_name == 'create' && params[:packages].size.zero?

    labels = SearchService::Label.new(
      to_date: @to_date,
      from_date: @from_date,
      reference: params[:reference],
      courier: params[:courier],
      commune: params[:commune],
      branch_offices: @company.branch_offices.ids,
      payable: params[:payable],
      destiny: params[:destiny],
      seller: params[:seller],
      per: params[:per],
      page: params[:page],
      format: @setting.printer_available['format'],
      packages: params[:packages],
      label_printed: params[:label_printed]
    ).search
    @total_shipments = labels[:total]
    @shipments = labels[:labels]
  rescue => e
    render_rescue(e)
  end

  def set_references
    @shipments = @company.packages.left_outer_joins(:address, address: :commune, commune: :region)
                         .where(status: [0, 13, 14, 6], reference: params[:references].split(','))
                         .not_sandbox.not_test.no_returned.without_checks.label_select.load
    raise unless @shipments.present?

    @total_shipments = @shipments.size
  rescue => e
    render json: { shipments: [], message: 'No se encontraron envíos con los parametros ingresados', state: :okish }, status: :ok
  end

  def set_dates
    @from_date = (params[:from_date].present? ? Date.parse(params[:from_date]) : (Date.current - 1.month)).strftime('%Y/%m/%d')
    @to_date = (params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current).strftime('%Y/%m/%d')
  end

  def set_setting
    @setting = Setting.printers(@company.id)
    @integrations = Setting.fullit(@company.id).sellers_availables.map { |seller| seller.keys.first }
  end

  def set_shipment
    @shipment = Package.find_by(id: params[:id]) if params[:id]
    raise unless @shipment.present?
  rescue StandardError => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def packages_params
    params.require(:packages).permit(Package.allowed_attributes)
  end
end
