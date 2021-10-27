class V::V3::PrintersController < V::ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_dates, only: %i[index create]
  before_action :set_company, only: %i[create massive]
  before_action :set_setting, only: %i[create massive]
  before_action :set_packages, only: %i[create massive]

  def create
    raise 'No tienes envíos por imprimir' if @packages.blank?
    download = @company.downloads.create(kind: :label, status: :pending) if @setting.printer_way == 'download'

    @setting.print_labels(@company.current_account, download, @packages)
    @company.prints.create(quantity: @packages.size)
    render json: { state: :ok, link: (download.present? ? download.link : ''), packages: @packages }, status: :ok
  rescue RuntimeError => e
    puts e.message.red.swap
    render json: { state: :error, message: e.message.to_s }, status: :not_found
  rescue => e
    puts e.message.red.swap
    render json: { state: :error, message: e.message.to_s }, status: :bad_request
  end

  def massive
    @company.prints.create(quantity: @packages.size)
    @packages = @company.packages.joins(:address, address: :commune, commune: :region).with_tracking.label_export.order(created_at: :desc)
    PrinterJob.perform_later(@packages, @setting.printer_available['id_printer'])
    render json: { state: :ok, message: 'Tú solicitud a sido procesada, enviaremos las etiquetas a la cola de impresión', packages: @packages }, status: :ok
  end

  private

  def set_company
    @company = current_account.current_company
  end

  def set_packages
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
      packages: params[:packages]
    ).search
    @total_packages = labels[:total]
    @packages = labels[:labels]
  end

  def set_setting
    @setting = Setting.printers(@company.id)
  end

  def set_dates
    @from_date = (params[:from_date].present? ? Date.parse(params[:from_date]) : 14.business_days.before(Date.current)).strftime('%Y/%m/%d')
    @to_date = (params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current).strftime('%Y/%m/%d')
  end

  def packages_params
    params.require(:packages).permit(Package.allowed_attributes)
  end
end
