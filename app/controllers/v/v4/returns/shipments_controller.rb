class V::V4::Returns::ShipmentsController < V::ApplicationController
  before_action :set_company
  before_action :set_shipments, only: %i[index]
  before_action :set_shipments_to_factoring, only: %i[factoring]
  before_action :set_shipment, only: %i[show buyer]
  before_action :set_dates, only: %i[index]
  before_action :validate_return, only: %i[buyer]
  before_action :build_return, only: %i[buyer]

  def index
    respond_with(@shipments, @total)
  end

  def factoring
    render :index
  end

  def show
    respond_with(@shipment)
  end

  def client
    raise 'Parametros no validos' unless params[:packages].present?
    raise 'Parametros no validos' if params[:packages].size.zero?
    raise StandardError unless ReturnToClientJob.perform_later(params[:packages].pluck(:id))

    render json: { state: :ok }, status: :ok
  rescue => e
    render_rescue(e)
  end

  def buyer
    raise StandardError unless @return.save!
    raise StandardError unless @shipment.update_columns(status: :returned, sub_status: 'returned', return_retry_date: DateTime.current)

    ReturnsMailer.buyer(@company, @return).deliver if Restriction.find_by(kind: 'available_return_emails').active && @return.email.present?
    render json: { state: :ok, message: "Envío creado correctamente. Se entregará al courier el día #{@return.operation_date.strftime('%d/%m/%Y')}" }, status: :ok
  rescue => e
    render_rescue(e)
  end

  def counter
    @counter = @company.packages.where(status: :at_shipit).count
    render json: { state: :ok, counter: @counter }, status: :ok
  rescue => e
    render_rescue(e)
  end

  private

  def set_company
    @company = company
  end

  def set_dates
    @from_date = (params[:from_date].present? ? Date.parse(params[:from_date]) : (Date.current - 1.year)).strftime('%d/%m/%Y')
    @to_date = (params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current).strftime('%d/%m/%Y')
    @date = { from: @from_date, to: @to_date }
  end

  def set_shipment
    @shipment = Package.left_outer_joins(:check, :insurance)
                       .joins(:address, :branch_office, :company, company: :entity, address: :commune)
                       .where(id: params[:id]).select_processed_active.first
    raise 'Envío no encontrado' unless @shipment.present?
  rescue => e
    render_rescue(e)
  end

  def set_shipments
    data = Package.filter_returned(current_account, params[:kind], params[:per], params[:page])
    @shipments = data[:shipments]
    @total = data[:total]
  end

  def set_shipments_to_factoring
    data = Package.where("EXTRACT(YEAR FROM packages.created_at) = ? AND EXTRACT(MONTH FROM packages.created_at) = ?", params[:year], params[:month])
                  .returned_processed(current_account).select_processed_active.order(return_created_at: :desc).load
    @shipments = Kaminari.paginate_array(data).page(params[:page]).per(params[:per])
    @total = data.size
  end

  def return_params
    params.require(:shipment).permit(Package.returned_attributes)
  end

  def validate_return
    raise 'No es posible generar el pedido' unless @shipment.returnable_by_client
  rescue => e
    render_rescue(e)
  end

  def build_return
    @return = Package.build_return(@company, return_params, @shipment)
  rescue => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
