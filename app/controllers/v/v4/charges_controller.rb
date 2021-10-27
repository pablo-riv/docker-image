class V::V4::ChargesController < V::ApplicationController
  before_action :set_company
  before_action :set_service
  before_action :set_date

  def index
    @charges = Charges::Generator.new(service: @service[:name],
                                      company: @company,
                                      kind: 'yearly',
                                      date: @date).run
    respond_with(@charges)
  end

  def show
    @charge = Charges::Generator.new(service: @service[:name],
                                     company: @company,
                                     kind: 'monthly',
                                     date: @date).run
    respond_with(@charges)
  end

  def download
    generator = Charges::Generator.new(service: @service[:name],
                                       company: @company,
                                       kind: params[:kind],
                                       date: @date)
    render json: { link: generator.make_download, state: :ok }, status: :ok
  end

  def details
    @charges = Charges::Generator.new(service: @service[:name],
                                      company: @company,
                                      kind: 'monthly',
                                      specific: params[:specific],
                                      per: params[:per],
                                      page: params[:page],
                                      date: @date).details
    raise 'Datos no encontrados' unless @charges.present?

    respond_with(@charges)
  rescue => e
    render_rescue(e)
  end

  def download_shipments_by_date
    date = Date.parse("#{params[:year]}/#{params[:month]}").strftime('%d/%m/%Y')
    @shipments = @company.packages.by_billing_date(params[:year], params[:month]).where(is_payable: false)
    download = @company.downloads.create(kind: :xlsx, status: :pending)
    link = Package.xlxs_file(@shipments, date, date, @company, download)
    raise I18n.t('errors.unprocessable') unless link.present?

    render json: { state: :ok, link: link }, status: :ok
  rescue => e
    render_rescue(e)
  end

  private

  def set_date
    month = params[:month] || Date.current.month
    year = params[:year] || Date.current.year
    @date = Date.parse("#{year}/#{month}")
  rescue ArgumentError => e
    render_rescue(e)
  end

  def set_company
    @company = company
  end

  def set_service
    @service = company.active_service
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
