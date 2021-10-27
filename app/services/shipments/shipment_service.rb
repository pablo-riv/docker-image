module Shipments
  class ShipmentService
    include Error
    attr_accessor :object, :errors

    def self.massive(shipments: [], success: [], errors: [])
      shipments.each do |shipment|
        response = {}
        begin
          response = new(shipment)
          data = response.create
          raise if response.errors.present?

          success << data
        rescue StandardError => e
          errors << response.errors
        end
      end
      { success: success, errors: errors }
    end

    def initialize(object)
      @object = object
      @errors = []
    end

    def build
      validate_params
      transform_inventories = inventory_activity
      { reference: reference,
        full_name: full_name,
        email: email,
        width: get_sizes_by_service(width, transform_inventories[:sizes], 'width'),
        length: get_sizes_by_service(length, transform_inventories[:sizes], 'length'),
        height: get_sizes_by_service(height, transform_inventories[:sizes], 'height'),
        weight: get_sizes_by_service(weight, transform_inventories[:sizes], 'weight'),
        inventory_activity: transform_inventories[:inventories],
        items_count: items_count,
        cellphone: cellphone,
        is_payable: is_payable,
        packing: packing,
        shipping_type: shipping_type,
        destiny: destiny,
        courier_for_client: courier_for_client,
        courier_selected: courier_for_client.present?,
        delivery_time: delivery_time,
        platform: platform,
        address_attributes: address,
        is_sandbox: sandbox?,
        branch_office_id: branch_office_id,
        algorithm: algorithm,
        algorithm_days: algorithm_days,
        courier_branch_office_id: courier_branch_office_id,
        service: service,
        shipping_price: shipping_price,
        shipping_cost: shipping_cost,
        total_price: total_price,
        without_courier: without_courier,
        insurance_attributes: insurance,
        mongo_order_seller: mongo_order_seller,
        order_id: order_id,
        seller_order_id: seller_order_id,
        processed_by_beetrack: processed_by_beetrack,
        reference_into_branch_office: reference_into_branch_office
      }.with_indifferent_access
    end

    def create
      shipment_template = build
      shipment = ::Package.new(shipment_template)
      available_comunes
      validate_errors
      @errors << ShipmentError::ShipmentDoesntBuild.new(shipment: shipment, bugtrace: e.backtrace[0]) unless shipment.save!
      @errors << ShipmentError::ShipmentDoesntPersist.new(shipment: shipment, bugtrace: e.backtrace[0]) unless shipment.persisted?

      shipment
    rescue => e
      @errors << ShipmentError::ShipmentCreationFailed.new(shipment: shipment || { reference: reference },
                                                           message: e.message,
                                                           bugtrace: e.backtrace[0]) if e.message.present?
      @errors
    end

    private

    def branch_office_id
      branch_office.id
    end

    def shipping_type
      'Normal'
    end

    def shipping_price
      @object[:shipping_price].presence
    end

    def shipping_cost
      @object[:shipping_cost].presence
    end

    def total_price
      @object[:total_price].presence
    end

    def total_is_payable
      @object[:total_is_payable].presence
    end

    def without_courier
      raise unless @object[:without_courier].present?

      @object[:without_courier]
    rescue StandardError => _e
      false
    end

    def delivery_time
      raise unless @object[:delivery_time].present?

      @object[:delivery_time]
    rescue StandardError => _e
      nil
    end

    def reference
      @object[:reference]
    end

    def full_name
      @object[:full_name]
    end

    def email
      @object[:email]
    end

    def items_count
      @object[:items_count]
    end

    def email
      @object[:email]
    end

    def sizes
      raise unless approx_size.present?

      approx_size.scan(/\d{2}x\d{2}x\d{2}/).first
    rescue StandardError => _e
      []
    end

    def approx_size
      @object[:approx_size]
    end

    def height
      @object[:height].try(:to_f).try(:abs) || sizes.first || 10.0
    end

    def width
      @object[:width].try(:to_f).try(:abs) || sizes.first || 10.0
    end

    def length
      @object[:length].try(:to_f).try(:abs) || sizes.first || 10.0
    end

    def weight
      @object[:weight].try(:to_f).try(:abs) || sizes.first || 1.0
    end

    def packing
      'Sin empaque'
    end

    def cellphone
      @object[:cellphone]
    end

    def courier_for_client
      courier = CourierService.normalize(@object[:courier_for_client])
      CourierService::NAMES.include?(courier) ? courier : ''
    rescue StandardError => _e
      ''
    end

    def mongo_order_seller
      raise unless @object[:mongo_order_seller].present?

      @object[:mongo_order_seller]
    rescue StandardError => _e
      ''
    end

    def mongo_order_id
      raise unless @object[:mongo_order_id].present?

      @object[:mongo_order_id]
    rescue StandardError => _e
      ''
    end

    def is_payable
      raise if @object[:is_payable].nil?

      @object[:is_payable]
    rescue StandardError => _e
      false
    end

    def destiny
      raise unless @object[:destiny].present?

      if %w[courier_branch_office sucursal chilexpress starken starken-turbus correoschile].include?(@object[:destiny].downcase)
        'sucursal'
      elsif ['retiro cliente', 'despacho retail'].include?(@object[:destiny].downcase)
        @object[:destiny].downcase
      else
        raise
      end
    rescue StandardError => _e
      'domicilio'
    end

    def courier_branch_office_id
      raise if @object[:courier_branch_office_id].try(:to_i).try(:zero?)
      raise unless destiny == 'sucursal'

      courier_branch_office = courier_branch_offices.find do |cbo|
        courier = cbo['courier_bo_id'].split('-')[0].strip
        courier.downcase.include?(courier_for_client.downcase) && cbo['commune_id'] == address['commune_id'].to_i
      end
      raise unless courier_branch_office.present?

      courier_branch_office['id']
    rescue StandardError => _e
      nil
    end

    def seller_order_id
      @object[:seller_order_id]
    end

    def order_id
      @object[:order_id]
    end

    def address
      {
        street: address_street,
        number: address_number,
        complement: address_complement,
        commune_id: address_commune_id
      }.with_indifferent_access
    end

    def address_street
      @object[:address_attributes][:street]
    end

    def address_number
      @object[:address_attributes][:number]
    end

    def address_complement
      @object[:address_attributes][:complement]
    end

    def address_commune_id
      commune.try(:id)

    rescue StandardError => e
      @errors << ShipmentError::ErrorCommuneNotFound.new(shipment: { reference: reference }, bugtrace: e.backtrace[0])
    end

    def commune
      commune =
        if @object[:address_attributes][:commune_id].present? || @object[:address_attributes][:commune_id].to_i > 0
          Commune.find_by(id: @object[:address_attributes][:commune_id].to_i)
        elsif @object[:address_attributes][:commune_name].present?
          Commune.find_by(name: @object[:address_attributes][:commune_name].strip)
        end
      raise 'Envío sin comuna' unless commune.present?

      commune
    rescue StandardError => e
      @errors << ShipmentError::ErrorCommuneNotFound.new(shipment: { reference: reference }, bugtrace: e.backtrace[0])
    end

    def available_comunes
      return true unless courier_for_client.present?
      return true if courier_for_client.try(:downcase) == 'fulfillment delivery'
      return true if ['retiro cliente', 'despacho retail'].include?(destiny.downcase)

      raise unless commune.available_for(courier_for_client.try(:downcase))
    rescue StandardError => e
      @errors << ShipmentError::ErrorNotCourierDestinyAvailable.new(shipment: { reference: reference }, bugtrace: e.backtrace[0])
    end

    def insurance
      data = insurance_attributes
      { ticket_number: data[:ticket_number],
        ticket_amount: data[:ticket_amount] || data[:amount],
        detail: data[:detail],
        extra: data[:extra] || data[:extra_insurance] }.with_indifferent_access
    rescue => e
      { ticket_number: '',
        ticket_amount: 0,
        detail: '',
        extra: false }.with_indifferent_access
    end

    def insurance_attributes
      @object[:insurance_attributes] || @object[:purchase]
    end

    def inventory_activity_orders_attributes
      @object[:inventory_activity][:inventory_activity_orders_attributes]
    end

    def inventory_activity
      raise 'Cliente sin servicio fulfillment' unless fulfillment.present?
      # validate if needs to calculate all sizes by skus
      inventory = inventory_activity_orders
      validate_errors
      measures =
        if inventory.size > 1
          BoxifyService.new(packages: boxify_request(inventory)).calculate
        elsif inventory.size == 1
          size = boxify_request(inventory)
          size[0][:quantity].to_i > 1 ? BoxifyService.new(packages: size).calculate : size[0]
        end
      {
        inventories: { inventory_activity_orders_attributes: inventory },
        sizes: measures
      }.with_indifferent_access
    rescue StandardError => _e
      { inventories: nil, sizes: [] }.with_indifferent_access
    end

    def boxify_request(skus_selected)
      skus_selected.map do |sku|
        warehouse_sku = find_skus(sku)
        { width: warehouse_sku['width'].to_f,
          length: warehouse_sku['length'].to_f,
          height: warehouse_sku['height'].to_f,
          weight: warehouse_sku['weight'].to_f,
          quantity: sku['amount'] }
      end
    end

    def inventory_activity_orders
      inventory = inventory_activity_orders_attributes.map do |sku|
        begin
          warehouse_sku = find_skus(sku)
          raise 'Sin stock diponible' unless warehouse_sku['amount'].positive?
          { sku_id: warehouse_sku['id'],
            amount: sku['amount'],
            warehouse_id: warehouse_sku['warehouse_id'],
            description: warehouse_sku['description'] }.with_indifferent_access
        rescue => e
          @errors << ShipmentError::ShipmentOutOfStrock.new(shipment: { reference: reference }, sku: warehouse_sku['id'], bugtrace: e.backtrace[0])
        end
      end
      validate_errors
      inventory
    rescue StandardError => e
      []
    end

    def find_skus(sku)
      skus.find { |item| item['id'] == sku['sku_id'] }
    end

    def get_sizes_by_service(measure, inventories_sizes, attribute)
      return measure unless fulfillment.present? && (inventories_sizes.present? && inventories_sizes[attribute].to_f > 0.0)

      inventories_sizes[attribute].to_f
    end

    def platform
      raise unless @object[:platform].present?

      @object[:platform]
    rescue StandardError => _e
      2
    end

    def service
      raise unless @object[:service].present?

      @object[:service]
    rescue StandardError => _e
      :pick_and_pack
    end

    def sandbox?
      @object[:branch_office].sandbox?
    rescue StandardError => _e
      false
    end

    def algorithm
      raise unless @object[:algorithm].present?
      raise unless @object[:algorithm].to_i.positive?

      @object[:algorithm].to_i
    rescue StandardError => _e
      opit_algorithm
    end

    def algorithm_days
      raise unless @object[:algorithm_days].present?
      raise unless @object[:algorithm_days].to_i.positive?

      @object[:algorithm_days].to_i
    rescue StandardError => _e
      opit_algorithm_days || 2
    end

    def branch_office
      @object[:branch_office]
    end

    def company
      @object[:company]
    end

    def opit
      @object[:opit]
    end

    def opit_algorithm
      opit.present? && opit.configuration['opit']['algorithm'].present? ? opit.configuration['opit']['algorithm'].to_i : 1
    end

    def opit_algorithm_days
      opit_algorithm == 2 && opit.configuration['opit']['algorithm_days'].to_i.positive? ? opit.configuration['opit']['algorithm_days'].to_i : 0
    end

    def fulfillment
      @object[:fulfillment]
    end

    def skus
      @object[:skus]
    end

    def courier_branch_offices
      @object[:courier_branch_offices]
    end

    def couriers
      @object[:couriers]
    end

    def processed_by_beetrack
      # courier_for_client == 'shippify'
      false
    end

    def reference_into_branch_office
      "#{branch_office.name}_#{reference}"
    end

    def courier_destiny_id
      @object[:courier_destiny_id]
    end

    def check_reference
      shipment = Package.unscoped.find_by(reference: reference, branch_office_id: branch_office.id)
      raise if shipment.present?

    rescue StandardError => _e
      @errors << ShipmentError::ErrorShipmentExist.new(shipment: shipment)
    end

    def check_carrier
      @carrier = Couriers::CourierGeneric.new(name: courier_for_client,
                                              type_of_destiny: destiny,
                                              payable: is_payable,
                                              reference: reference,
                                              commune_id: address_commune_id).instance
      raise unless @carrier.valid_shipment

    rescue StandardError => _e
      @errors << @carrier.errors.pop
    end

    def validate_params
      check_reference
      check_carrier
    end

    def validate_errors
      raise if @errors.present?
    end
  end
end
