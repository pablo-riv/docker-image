class V::V4::Fulfillment::SkusController < V::ApplicationController
  before_action :set_company
  before_action :set_fulfillment
  before_action :set_skus, only: %i[index]
  before_action :set_all_skus, only: %i[all]
  before_action :set_sku, only: %i[show]

  def index
    respond_with(@skus)
  end

  def all
    respond_with(@skus)
  end

  def show
    respond_with(@sku)
  end

  def by_name
    @sku = FulfillmentService.sku_by_client_and_name(@company.id, params[:name])
    raise 'SKU no encontrado' unless @sku.present?

    respond_with(@sku)
  rescue => e
    render_rescue(e)
  end

  def create
  rescue => e
    render_rescue(e)
  end

  def update_min_stock
    params[:skus].each do |sku|
      FulfillmentService.update_min_stock(sku)
    end
    render json: { message: "SKU'S Actualizados", state: :ok }, status: :ok
  rescue => e
    render_rescue(e)
  end

  def destroy
  rescue => e
    render_rescue(e)
  end

  def download
    SkusDownloadJob.perform_now(company: @company,
                                account: current_account,
                                availables: params[:availables],
                                per: params[:per],
                                query: params[:query],
                                value: params[:value])
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

  def set_skus
    data = SearchService::Sku.new(company_id: @company.id, query: params[:query], value: params[:value], availables: params[:availables], per: params[:per], page: params[:page]).search
    @skus = data[:skus]
    @total = data[:total]
  end

  def set_all_skus
    data = FulfillmentService.by_client(@company.id)
    raise 'Skus no encontrados' unless data.present?

    @skus = data.map { |sku| RecursiveOpenStruct.new(sku, recurse_over_arrays: true) }
  rescue => e
    render_rescue(e)
  end

  def set_sku
    @sku = RecursiveOpenStruct.new(FulfillmentService.sku_by_client(@company.id, params[:id]))
    raise 'SKU no encontrado' unless @sku.try(:id).try(:present?)

  rescue => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end
end
