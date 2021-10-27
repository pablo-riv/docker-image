class V::V4::ShipmentsController < V::ApplicationController
  before_action :set_dates, only: %i[index show massive_archive destroy download counter]
  before_action :set_company
  before_action :set_branch_office, only: %i[index show create update massive massive_import check_reference dispatch_date by_reference]
  before_action :set_shipments, only: %i[index counter]
  before_action :set_shipment, only: %i[show destroy update]
  before_action :set_order, only: %i[create]
  before_action :set_orders, only: %i[massive]
  before_action :set_opit, only: %i[create massive massive_import]
  before_action :set_fulfillment, only: %i[create massive massive_import]
  before_action :set_skus, only: %i[create massive massive_import]
  before_action :set_notification, only: %i[create massive massive_import]
  before_action :set_couriers, only: %i[create massive massive_import]
  before_action :set_couriers_branch_offices, only: %i[create massive massive_import]
  before_action :set_shipments_by_id, only: %i[massive_archive dispatch_date]

  def index
    respond_with(@shipments, @total)
  end

  def show
    respond_with(@shipment)
  end

  def create
    Package.transaction do
      order = @order.present? ? @order : Order.new(order_params.merge!(company_id: @company.id))
      # REVIEW DUPLACATED REQUEST WITH BOXIFY.
      shipment_trans = order.transform_shipment(@fulfillment.present?).merge(
        company: @company,
        branch_office: @branch_office,
        fulfillment: @fulfillment,
        opit: @opit,
        couriers: @couriers,
        courier_branch_offices: @courier_branch_offices,
        skus: @skus
      ).with_indifferent_access
      data = Shipments::ShipmentService.massive(shipments: [shipment_trans])
      return shipments_rescue(data) if data[:errors].present?

      @shipment = data[:success].first
    end
    Shipments::NotificationService.new(shipments: [@shipment],
                                       account: current_account,
                                       company: @company,
                                       branch_office: @branch_office,
                                       fulfillment: @fulfillment,
                                       notification: @notification).dispatch
    update_orders_state([@order], [@shipment])
    @shipment.calculate_total if @shipment.shipping_price.positive?
    respond_with(@shipment)
  rescue => e
    render_rescue(e)
  end

  def massive
    Package.transaction do
      shipments_trans = @orders.map do |order|
        order.transform_shipment(@fulfillment.present?).merge(
          company: @company,
          branch_office: @branch_office,
          fulfillment: @fulfillment,
          opit: @opit,
          couriers: @couriers,
          courier_branch_offices: @courier_branch_offices,
          skus: @skus
        ).with_indifferent_access
      end
      data = Shipments::ShipmentService.massive(shipments: shipments_trans)
      @shipments = data[:success]
      Shipments::NotificationService.new(shipments: @shipments,
                                      account: current_account,
                                      company: @company,
                                      branch_office: @branch_office,
                                      fulfillment: @fulfillment,
                                      notification: @notification).dispatch if @shipments.size.positive?
      update_orders_state(@orders, @shipments)
      data[:errors].present? ? shipments_rescue(data) : respond_with(@shipments)
    end
  rescue => e
    render_rescue(e)
  end

  def massive_import
    Package.transaction do
      shipments_trans = orders_params.map do |order|
        Order.new(order.merge!(company_id: @company.id)).transform_shipment(@fulfillment.present?).merge(
          company: @company,
          branch_office: @branch_office,
          fulfillment: @fulfillment,
          opit: @opit,
          couriers: @couriers,
          courier_branch_offices: @courier_branch_offices,
          skus: @skus
        ).with_indifferent_access
      end
      data = Shipments::ShipmentService.massive(shipments: shipments_trans)
      @shipments = data[:success]
      Shipments::NotificationService.new(shipments: @shipments,
                                         account: current_account,
                                         company: @company,
                                         branch_office: @branch_office,
                                         fulfillment: @fulfillment,
                                         notification: @notification).dispatch if @shipments.size.positive?
      data[:errors].present? ? shipments_rescue(data) : respond_with(@shipments)
    end
  rescue => e
    render_rescue(e)
  end

  def update
    raise unless @shipment.editable_by_client
    raise @shipment.errors.add(:reference) unless @shipment.update!(shipments_params)

    # Business rules: to enable Shippify as next day courier
    processed_by_beetrack = !@shipment.courier_for_client.present?
      # if shipment_courier_for_client == 'shippify' && @shipment.courier_for_client != 'shippify'
      #   processed_by_beetrack = false
      # elsif shipment_courier_for_client != 'shippify' && @shipment.courier_for_client == 'shippify'
      #   processed_by_beetrack = true
      # end
    @shipment.update_columns(processed_by_beetrack: processed_by_beetrack)
    # end
    @shipment.new_tracking
    Notifications::BuyerNotificationService.dispatch(@shipment) if need_alert_notification?
    respond_with(@shipment)
  rescue => e
    render json: { message: 'No estas autorizado para actualizar este envío!',
                   error: e.message,
                   bug_trace: e.backtrace[0] },
           status: :bad_request
  rescue => e
    render_rescue(e)
  end

  def destroy
    raise unless @shipment.archivable_by_client
    raise unless @shipment.update_columns(is_archive: true)

    render json: { message: 'Envío eliminado' }, status: :ok
  rescue => e
    render json: { state: :error, message: 'No estás autorizado para eliminar este envío!', error: e.message, bug_trace: e.backtrace[0] }, status: :bad_request
  rescue => e
    render_rescue(e)
  end

  def massive_archive
    Package.transaction do
      archivables = @shipments.select(&:archivable_by_client)
      raise 'No es posible eliminar los envíos seleccionados' unless archivables.present?

      archivables.each do |shipment|
        shipment.update_columns(is_archive: true)
        Opit.new(shipment, false).remove_shippify_tracking if shipment.courier_for_client == 'shippify'
      end
    end
    render json: { message: 'Envíos eliminados', error: @shipments.reject(&:archivable_by_client) }, status: :ok
  rescue => e
    render json: { state: :error, message: e.message, bug_trace: e.backtrace[0] }, status: :bad_request
  rescue => e
    render_rescue(e)
  end

  def download
    download = @company.downloads.create(kind: :xlsx, status: :pending)
    ShipmentDownloadJob.perform_later(download: download,
                                      account: current_account,
                                      company: @company,
                                      from_date: @date[:from],
                                      to_date: @date[:to],
                                      state: params[:state],
                                      payables: params[:payable],
                                      returned: params[:returned],
                                      courier: params[:courier],
                                      branch_offices: @company.branch_offices.ids,
                                      per: params[:per],
                                      page: params[:page],
                                      destiny: params[:destiny_kind],
                                      query: params[:query] || params[:reference],
                                      label_printed: params[:label_printed],
                                      communes: params[:communes])
    render json: { state: :ok, message: I18n.t('activerecord.attributes.download.pending') }, status: :ok
  rescue => e
    render_rescue(e)
  end

  def counter
    sizes = { total: @total }
    shipments = @shipments.group_by { |shipment| shipment['status'] }
    shipments.each { |state| sizes.merge!(state.first => state.last.size) }
    render json: { state: :ok, sizes: sizes }, status: :ok
  rescue => e
    render_rescue(e)
  end

  def monthly
    data = @company.packages.where("packages.is_payable = ? AND EXTRACT(YEAR FROM packages.created_at) = ? AND EXTRACT(MONTH FROM packages.created_at) = ?", params[:payables], params[:year], params[:month]).order('packages.id DESC')

    @shipments = Kaminari.paginate_array(data).page(params[:page]).per(params[:per])
    @total = data.size

    render :index
  rescue => e
    render_rescue(e)
  end

  def check_reference
    package = Package.unscoped.where(reference: params['reference'], branch_office_id: @branch_office.id)
    render json: { state: :ok, response: package.present? }, status: :ok
  rescue => e
    render_rescue(e)
  end

  def dispatch_date
    Package.transaction do
      raise 'Error al encontrar envíos' unless @shipments.present?
      raise 'Solo es posible retirar días hábiles, selecciona otra fecha' if params[:operation_date].to_date.holiday?(:custom_cl) || params[:operation_date].to_date.is_weekend?
      if params[:operation_date].to_date == Date.current
        reschedule_datetime = DateTime.parse(params[:operation_date] + DateTime.current.strftime("T%H:%M:%S%Z"))
        time = CuttingHours::Generator.new(model: @company).calculate_cutting_hour
        cutting_hour = DateTime.parse("#{params[:operation_date]}T#{time}")
        raise 'Ya no es posible reagendar envíos para hoy, selecciona otra fecha.' if reschedule_datetime > cutting_hour
      end

      selected = @shipments.select(&:not_retired)
      rejected = @shipments.reject(&:not_retired)
      pickup = PickupService.new(date: params['operation_date'].to_date,
                                 branch_office: @branch_office,
                                 account: current_account,
                                 shipments: selected)
      pickup.update_shipment_dispatch
      pickup.add_shipments_to_pickup
      render json: { state: :ok, response: selected, reject: rejected }, status: :ok
    end
  rescue StandardError => e
    render_rescue(e)
  end

  def by_reference
    @shipments = Package.where(branch_office: @branch_office.id, reference: params[:reference])
    raise if @shipments.size.zero?

    @total = @shipments.size
    respond_with(@shipments, @total)
  rescue StandardError => e
    render_rescue(e)
  end

  private

  def set_shipments_by_id
    @shipments = @company.packages.where(id: params['ids'])
  end

  def need_alert_notification?
    !@shipment.tracking_number.present? && @shipment.is_payable && shipments_params[:tracking_number].present?
  end

  def set_company
    @company = company
  end

  def set_branch_office
    @branch_office = branch_office
  end

  def set_opit
    @opit = Setting.opit(company.id)
  end

  def set_notification
    @notification = Setting.notification(@company.id)
  end

  def set_couriers
    @couriers = Prices.new(current_account).couriers
  end

  def set_couriers_branch_offices
    @courier_branch_offices = Prices.new(current_account).branch_offices
  end

  def set_fulfillment
    @fulfillment = Setting.fulfillment(@company.id)
  end

  def set_skus
    @skus = FulfillmentService.by_client(@company.id) if @fulfillment.present?
  end

  def set_shipments
    @data = SearchService::Shipment.new(from_date: @date[:from],
                                        to_date: @date[:to],
                                        state: params[:state],
                                        payables: params[:payable],
                                        returned: params[:returned],
                                        courier: params[:courier],
                                        branch_offices: @company.branch_offices.ids,
                                        current_account: current_account,
                                        per: params[:per],
                                        page: params[:page],
                                        destiny: params[:destiny_kind],
                                        query: params[:query] || params[:reference],
                                        ids: params[:ids],
                                        label_printed: params[:label_printed],
                                        sorter: params[:sorter],
                                        sorter_by: params[:sorter_by],
                                        communes: params[:communes]).search
    @shipments = @data[:shipments]
    @total = @data[:total]
  rescue => e
    render_rescue(e)
  end

  def set_shipment
    @shipment = @company.packages.find_by(id: params[:id])
    raise 'Envío no encontrado' unless @shipment.present?
  rescue => e
    render_rescue(e)
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def shipments_rescue(data)
    data[:errors].flatten.each { |error| Rails.logger.info { "ERROR: #{error.message}\nBUGTRACE#{error.bugtrace}\n\n".red.swap } }
    messages = data[:errors].flatten.map(&:message)
    render json: { success: data[:success].size, errors: data[:errors].size, message: "#{messages.join("\n")}", state: :error }, status: :bad_request
  end

  def set_dates
    @from_date = (params[:from_date].present? ? Date.parse(params[:from_date]) : (Date.current - 1.month)).strftime('%d/%m/%Y')
    @to_date = (params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current).strftime('%d/%m/%Y')
    @date = { from: @from_date, to: @to_date }
  end

  def set_order
    @order = company.orders.find_by(id: params[:order][:id]) if params[:order] && params[:order][:id]
    @order.update_columns(order_params.to_h) if @order.present?
  rescue => e
    render_rescue(e)
  end

  def set_orders
    @orders = company.orders.where(id: params[:orders][:ids]) if params[:orders].present?
    raise 'No se encontraron órdenes a procesar' unless @orders.present?
  rescue => e
    render_rescue(e)
  end

  def shipments_params
    params.require(:shipment).permit(Package.allowed_attributes)
  end

  def order_params
    params.require(:order).permit(Order.allowed_attributes)
  rescue StandardError => _e
    params.require(:shipment).permit(Order.allowed_attributes)
  end

  def orders_params
    params.require(:orders).map do |order|
      order.permit(Order.allowed_attributes)
    end
  rescue StandardError => _e
    params.require(:shipments).map do |order|
      order.permit(Order.allowed_attributes)
    end
  end

  def update_orders_state(orders, shipments)
    return unless orders.present?

    orders.each do |order|
      next unless order.try(:persisted?)
      next unless shipments.pluck(:reference).include?(order.try(:reference))

      order.update_columns(state: :deliver, package_id: order.package.try(:id))
      Publisher.publish('reindex_order', {id: order.id})
    end
  end
end
