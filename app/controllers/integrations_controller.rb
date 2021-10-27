class IntegrationsController < ApplicationController
  before_action :set_orders_by_seller, only: %i[show]
  before_action :set_service, only: %i[index push_orders integration_orders]
  before_action :set_order, only: %i[update_order]
  before_action :skus_by_client, only: %i[index push_orders integration_orders], if: [:set_service]
  before_action :set_date, only: %i[index integration_orders download]

  def index; end

  def integration_orders
    @orders = OrderService.ready_to_deliver(per: params[:per],
                                            from_date: @from_date,
                                            to_date: @to_date,
                                            seller_reference: params[:seller_reference],
                                            page: params[:page],
                                            filter: params[:filter] || 'todos',
                                            company_id: current_account.entity_specific.id)
    render json: { state: :ok, data: { total_orders: @orders[:total_orders], filter: @orders[:filters], orders: @orders[:oss], has_fulfillment: @setting_fulfillment.present?, skus: @sku_client } }, status: :ok
  rescue StandardError => e
    puts "#{e.message} \n #{e.backtrace.first(5).join("\n")}".red
    render json: { state: :error, error: e.message }, status: :bad_request
  end

  def is_downloading
    download_record = DownloadService.where(company_id: current_account.entity_specific.id).first
    download_record.update_last_download(false) if !download_record.blank? && download_record['last_time'] + 15.minutes < DateTime.now
    render json: { state: :on, data: DownloadService.where(company_id: current_account.entity_specific.id).first }, status: :ok
  rescue StandardError => e
    render json: { state: :error, data: nil }, status: :bad_request
  end

  def push_orders
    render json: { state: 400, error: 'No ha seleccionado órdenes ' }, status: :error if params[:orders].blank?
    results = OrderService.make_packages(order_parameters, current_account, @sku_client, @setting_fulfillment, @opit)
    packages = results.select { |result| result.class.name == 'Package' && !result.same_day_delivery? }.compact
    errors =  ''
    results.select { |result| result.class.name == 'String' }.each { |error| errors += errors.blank? ? error : ", #{error}" }
    raise errors if packages.blank?
    render json: { state: 200, response: "#{packages.count} Órdenes ingresadas exitosamente!", errors: errors }, status: :ok
  rescue StandardError => e
    Rails.logger.debug { e.message.red }
    message = e.class == RuntimeError ? e.message : 'Ocurrió un problema mientras se agregaban unas órdenes. Intente de nuevo más tarde.'
    render json: { state: 500, error: message }, status: :error
  end

  def download_csv
    respond_to do |format|
      format.html
      format.csv { send_data OrderService.to_csv(current_account), filename: "orders-#{Date.today}.csv" }
    end
  end

  def download_plugin
    path = "#{Rails.root}/app/assets/docs/api2cart_bridges/#{params[:store]}/bridge_connector.zip"
    send_file path, type: 'application/zip',
                    disposition: 'attachment',
                    filename: 'bridge_connector.zip'
  end

  def download_pdf
    path = "#{Rails.root}/app/assets/docs/integrations/#{params[:store]}.pdf"
    send_file path, type: 'application/pdf',
                    disposition: 'attachment',
                    filename: "#{params[:store]}.pdf"
  end

  def download
    @setting_fullit = current_account.entity_specific.settings.fullit(current_account.entity_specific.id)
    @setting_fullit.sync_seller_orders(@from_date.to_datetime.beginning_of_day.to_s, @to_date.to_datetime.at_end_of_day.to_s)
    render json: { state: :ok, data: 'Se estan descargando tus órdenes' }, status: :ok
  rescue StandardError => e
    render json: { state: :error, error: 'No pudimos enviar a descargar tus órdenes, porfavor intentelo denuevo mas tarde.' }, status: :bad_request
  end

  def faq; end

  def archive
    order = OrderService.find(params[:order_id]) unless params[:order_id].blank?
    order['archive'] = params[:archive]
    order.save
    render json: { state: :ok, response: order }, status: :ok
  rescue StandardError => e
    render json: { state: :error, error: e.message }, status: :bad_request
  end

  def update_order
    raise unless @order.update(edit_order_params)

    render json: { state: :ok, order: @order }, status: :ok
  rescue StandardError => e
    render json: { state: :error, error: e.message }, status: :bad_request
  end

  def by_refereneces
    orders = params[:orders].map { |order| OrderService.where(company_id: current_account.current_company.id, seller_reference: order['seller_reference'], seller: order['seller'], sent: false).first }.compact
    raise 'No se encontraron ordenes...' unless orders.present?

    render json: { state: :ok, orders: orders }, status: :ok
  rescue StandardError => e
    render json: { state: :error, error: e.message }, status: :bad_request
  end

  private

  def set_orders_by_seller
    @seller = params[:id] if params[:id]
  end

  def skus_by_client
    @sku_client = FulfillmentService.by_client(current_account.current_company.id)
  end

  def set_service
    @setting_fulfillment = current_account.current_company.services.find_by(name: 'fulfillment')
    @opit = Setting.opit(current_account.current_company.id)
  end

  def set_order
    @order = OrderService.find_by(_id: params[:id]) unless params[:id].blank?
  end

  def set_date
    @from_date = params[:from_date] || (Date.current - 1.weeks).strftime('%d/%m/%Y')
    @to_date = params[:to_date] || Date.current.strftime('%d/%m/%Y')
  end

  def order_parameters
    params.permit(orders: [:order_id, :packing, :shipping_data_complement, :customer_name, :package_payable, :package_destiny, :package_courier_selected, :package_courier_for_client, :package_cbo, commune: [:name], _id: [:$oid], shipping_data: [:street, :number]])
  end

  def edit_order_params
    params.require(:order).permit(:order_id, :packing, :shipping_data_complement, :customer_name, :customer_email, :customer_phone, :package_payable, :package_destiny, :package_courier_for_client, :package_cbo, commune: [:name], shipping_data: [:street, :number])
  end
end
