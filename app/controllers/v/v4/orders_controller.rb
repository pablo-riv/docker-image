class V::V4::OrdersController < V::ApplicationController
  before_action :set_dates, only: %i[index]
  before_action :set_company
  before_action :set_orders, only: %i[index]

  def index
    respond_with(@orders, @total)
  end

  private

  def set_company
    @company = company
  end

  def set_orders
    data = SearchService::Order.new(from_date: @date[:from],
                                    to_date: @date[:to],
                                    destiny_kind: params[:destiny_kind],
                                    state: params[:state],
                                    payables: params[:payable],
                                    courier: params[:courier],
                                    company: @company,
                                    communes: params[:communes],
                                    destiny: params[:destiny],
                                    per: params[:per],
                                    page: params[:page],
                                    seller: params[:seller],
                                    search: params[:query] || params[:reference]).search
    @orders = data[:orders]
    @total = data[:total]
    raise 'Sin órdenes disponibles' unless @orders.present?
  rescue StandardError => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def set_dates
    @from_date = params[:from_date].presence || (Date.current - 1.month).strftime('%d/%m/%Y')
    @to_date = params[:to_date].presence || Date.current.strftime('%d/%m/%Y')
    @date = { from: Date.parse(@from_date), to: Date.parse(@to_date) }
  end

  def orders_params
    params.require(:orders).map do |order|
      order.permit(Order.allowed_attributes)
    end
  end
end
