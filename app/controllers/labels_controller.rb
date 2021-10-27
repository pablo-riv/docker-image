class LabelsController < ApplicationController
  before_action :prepare_params, only: %i[index today search]
  before_action :set_company
  before_action :set_printer, only: %i[today search by_reference]
  before_action :set_packages, only: %i[today search]
  before_action :set_package, only: %i[by_reference]

  def index; end

  def today
    render json: { packages: @packages, setting: @setting, integration: @integration, total_packages: @total_packages }, status: :ok
  rescue => e
    puts "MESSAGE: #{e.message}\nBUGTRACE: #{e.backtrace[0]}".red.swap
    render json: [], status: :bad_request
  end

  def search
    render json: { packages: @packages, total_packages: @total_packages }, status: :ok
  rescue => e
    puts "MESSAGE: #{e.message}\nBUGTRACE: #{e.backtrace[0]}".red.swap
    render json: [], status: :bad_request
  end

  def pack; end

  def daily_printed
    packages = @company.packages.joins(:address, address: :commune).with_tracking.with_courier
      .where(label_printed: true, printed_date: Date.current).select('packages.id, packages.reference, packages.full_name, packages.courier_for_client, packages.tracking_number, packages.created_at, communes.name AS commune_name, packages.label_printed')
    render json: { state: :ok, packages: packages }, status: :ok
  rescue StandardError => e
    render json: { state: :ok, packages: [], message: e.message }, status: :bad_request
  end

  def by_reference
    PrinterService.new(package: @package,
                       printer: @setting.printer_available['id_printer'],
                       job_name: 'printing-ticket-for-label-clients').deliver
    @package.update_columns(label_printed: true, printed_date: Date.current)
    render json: { state: :ok, package: @package.print_attributes }, status: :ok
  rescue StandardError => e
    render json: { state: :ok, packages: [], message: e.message }, status: :bad_request
  end

  private

  def set_company
    @company = current_account.current_company
  end

  def set_printer
    @setting = Setting.printers(@company.id)
    @integration = Setting.fullit(@company.id).sellers_availables.map { |seller| seller.keys.first }
  end

  def set_package
    @package = @company.packages.left_outer_joins(:address, address: :commune, commune: :region)
                                .no_returned.with_tracking.with_courier
                                .where.not("LOWER(packages.courier_for_client) = 'chilexpress' AND packages.is_payable = true")
                                .find_by(reference: params[:reference], created_at: 10.business_days.before(Date.current)..Date.current)
    raise 'Envio no encontrado' unless @package.present?
  rescue StandardError => e
    render json: { state: :ok, packages: [], message: e.message }, status: :bad_request
  end

  def set_packages
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
    @packages = Kaminari.paginate_array(labels[:labels]).page(params[:page]).per(params[:per])
  end

  def prepare_params
    @from_date = (params[:from].try(:to_date) || (Date.current - 1.month)).strftime('%d/%m/%Y')
    @to_date = (params[:to].try(:to_date) || Date.current).strftime('%d/%m/%Y')
  end
end
