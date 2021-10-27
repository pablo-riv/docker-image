
module Apiable
  extend ActiveSupport::Concern

  module ClassMethods
    def massive_create(packages: [], account: {}, branch_office: {}, fulfillment: nil, opit: nil)
      notification = Setting.notification(branch_office.company_id)
      @data = []
      courier_branch_offices = Prices.new(account).branch_offices
      has_test_packages = packages.map { |p| p['reference'].to_s.downcase.start_with?('test-') }.include?(true)

      is_sandbox = branch_office.sandbox?
      opit_algorithm = 1
      opit_algorithm_days = ''
      if opit.present? && opit.configuration['opit']['algorithm'].present?
        opit_algorithm = opit['configuration']['opit']['algorithm'].to_i

        if opit_algorithm == 2
          opit_algorithm_days = opit.configuration['opit']['algorithm_days'].to_i
          opit_algorithm_days = 2 if opit_algorithm_days <= 1
        end
      end

      packages = packages.map do |p|
        p['platform'] =
          if p['platform'].present?
            p['platform']
          else
            p['mongo_order_seller'].present? || p['mongo_order_id'].present? || p['seller_order_id'].present? ? 3 : 2
          end
        p['is_sandbox'] = is_sandbox
        p['branch_office_id'] = p['branch_office_id'].present? ? p['branch_office_id'] : branch_office.id
        p['courier_for_client'] = CourierService.normalize(p['courier_for_client'])
        p['mongo_order_id'] = p['mongo_order_id'].to_s
        p['algorithm'] = opit_algorithm.try(:to_i).try(:positive?) ? opit_algorithm : 1
        p['algorithm_days'] = opit_algorithm_days.try(:to_i).try(:positive?) ? opit_algorithm_days : 2
        p['packing'] = 'Sin Empaque' # bussines rules apply 04/01/2019
        p['courier_branch_office_id'] = nil unless p['courier_branch_office_id'].to_i.positive?
        p['inventory_activity'] = nil unless branch_office.company.fulfillment?
        p['processed_by_beetrack'] = p['courier_for_client'] == 'shippify'
        p = Package.determine_warehouse_address(p) if p['without_courier'] && !fulfillment.blank?
        p
      end
      @data = PackageService.set_new_massive(packages, branch_office, fulfillment, courier_branch_offices)
      raise 'No se pudieron crear los envíos, por favor revise los parámetros.' if @data.blank? || @data.size.zero?
      raise 'Tu pedido no ha podido ser procesado.' unless @data.is_a?(Array)

      if @data.first.is_returned
        ReturnedMailer.returned(@data, account).deliver
      else
        PackageService.pickup_email(@data, account, branch_office, has_test_packages, is_sandbox, notification.pickup_alert)
      end
      FulfillmentPackageJob.perform_later(@data, branch_office.company) if fulfillment.present?
      WebhookJob.perform_later(@data) if branch_office.company.webhook_pp_available.present?
      Publisher.publish('mass', Package.generate_template_for(3, PackageService.packages_to_pickup(@data), account)) if fulfillment.blank? && !has_test_packages && !is_sandbox
      @data
    rescue StandardError => e
      channel = branch_office.company.fulfillment? ? '#bugs_urgentes_ops' : '#ti_alert'
      slack = Slack::Ti.new({}, {})
      slack.alert(nil, "Error al crear pedidos: #{e.message}\nBacktrace: #{e.backtrace[0]}\n*PACKAGES*: #{@data.pluck(:id)}", channel)
      if branch_office.company.fulfillment?
        unless @data.size.zero?
          @data.each do |package|
            package.restore_ff_activity if package.fulfillment?
            slack.alert(nil, "RESTAURANDO INVENTARIO FULFILLMENT PARA EL ENVIO: #{package.id}", channel)
          end
        end
      end
      message = "Hubo un problema intentando crear pedidos: #{e.message}"
      puts message.red
      unless account.email.downcase == 'fabiola@experienciamonoi.cl'
        NotificationMailer.generic('Error al crear pedido', "#{message} \nfirst: #{@data.first} \ntotal: #{@data} \nparameters: #{packages}", account.entity_specific).deliver_now
      end
      NotificationMailer.failed_to_client('Error al procesar sus envíos', account, message).deliver_now
      Rollbar.error(e)
      raise message
    end

    def valid_ff_format(ff_packages)
      ff_packages.each do |pack|
        warehouse_id = 0
        pack['inventory_activity']['inventory_activity_orders_attributes'] = pack['inventory_activity']['inventory_activity_orders_attributes'].is_a?(Array) ? pack['inventory_activity']['inventory_activity_orders_attributes'] : pack['inventory_activity']['inventory_activity_orders_attributes'].values
        pack['inventory_activity']['inventory_activity_orders_attributes'] =
          pack['inventory_activity']['inventory_activity_orders_attributes'].map.with_index do |order, index|
            sku = FulfillmentService.sku(order['sku_id'])
            raise "SKU #{order['sku_id']} no existe" if sku.blank?
            company_id = BranchOffice.find(pack["branch_office_id"]).company_id
            if company_id != sku['company_id']
              raise 'Sku no pertenece a la compañía'
            end
            order['warehouse_id'] = sku['warehouse_id']
            warehouse_id = sku['warehouse_id']
            order
          end
      end
    end

    def determine_warehouse_address(package)
      sku = FulfillmentService.sku(package['inventory_activity']['inventory_activity_orders_attributes'].first['sku_id'])
      warehouse_id = sku['warehouse_id'] unless sku.blank?
      warehouses = FulfillmentService.warehouses
      warehouse_address = Address.find_by(id: warehouses.find { |warehouse| warehouse['id'] == warehouse_id }['address_id'] )
      return package if warehouse_address.blank?
      package['address_attributes']['street'] = warehouse_address.street
      package['address_attributes']['number'] = warehouse_address.number
      package['address_attributes']['complement'] = warehouse_address.complement
      package['address_attributes']['commune_id'] = warehouse_address.commune_id
      package
    end
  end
end
