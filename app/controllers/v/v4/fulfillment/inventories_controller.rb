class V::V4::Fulfillment::InventoriesController < V::ApplicationController
  before_action :set_company
  before_action :set_dates, only: %i[index download]
  before_action :set_skus, only: %i[download]
  before_action :set_fulfillment
  before_action :set_activities, only: %i[index]
  before_action :set_activity, only: %i[show]

  def index
    # in = inventory_activity_type_ids = [2]
    # out = inventory_activity_type_ids = [1,3]
    respond_with(@activities)
  end

  def show
    respond_with(@activity)
  end

  def download
    response = InventoryDownloadJob.perform_now(company: @company,
                                                account: current_account,
                                                query: params[:query],
                                                value: params[:value],
                                                from_date: @from_date,
                                                to_date: @to_date,
                                                skus: @skus)
    render json: { state: :ok, message: I18n.t('activerecord.attributes.download.pending') }, status: :ok
  end

  private

  def set_company
    @company = company
  end

  def set_fulfillment
    @fulfillment = Setting.fulfillment(@company.id)
    raise 'Cliente sin servicio fulfillment activo' unless @fulfillment.present?
  rescue => e
    render_rescue(e)
  end

  def set_activities
    raise unless params[:inventory_activity_type_ids].present?

    @activities = SearchService::Inventory.new(company_id: @company.id,
                                               types: params[:inventory_activity_type_ids],
                                               query: params[:query],
                                               value: params[:value],
                                               per: params[:per],
                                               page: params[:page],
                                               from_date: @from_date,
                                               to_date: @to_date).search
  rescue => e
    render_rescue(e)
  end

  def set_dates
    @from_date = (params[:from_date].present? ? Date.parse(params[:from_date]) : (Date.current - 1.year)).strftime('%d/%m/%Y')
    @to_date = (params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current).strftime('%d/%m/%Y')
    @date = { from: @from_date, to: @to_date }
  end

  def set_activity
    @activity = RecursiveOpenStruct.new(FulfillmentService.inventory(params[:id]))
  end

  def set_skus
    @skus = FulfillmentService.by_client(@company.id)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :unprocessable_entity
  end
end
