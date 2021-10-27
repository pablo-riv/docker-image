module PackageTemplates
  extend ActiveSupport::Concern

  included do
    def self.shopify_order(branch_office, package = {})
      inventory_activity_orders = lambda do |items|
        items.map do |item|
          {
            'sku' => item['sku'],
            'quantity' => item['quantity']
          }
        end
      end
      seller_format = {
        package_destiny: define_destiny(package['destiny']),
        package_courier_for_client: define_courier(package['courier_for_client']),
        package_courier_selected: define_courier_selected(package['courier_for_client']),
        package_payable: define_payable(package['is_payable']),
        address_shipping: {
          name: package['full_name'],
          phone: package['cellphone'],
          address1: package['address_attributes']['street'],
          number: package['address_attributes']['number'],
          address2: package['address_attributes']['complement'],
          city: Commune.find_by(id: package['address_attributes']['commune_id']).try(:name)
        },
        fulfillment_status: 'pending',
        financial_status: 'paid',
        created_at: package['created_at'] || Time.current,
        email: package['email'],
        name: package['reference'],
        order_id: package['order_id'],
        items: (inventory_activity_orders.call(package['inventory_activity']['inventory_activity_orders_attributes']) unless package['inventory_activity'].blank?)
      }
      base_format(branch_office, package).merge(seller_format)
    end

    def self.woocommerce_order(branch_office, package = {})
      inventory_activity_orders = lambda do |items|
        { 'product' => items.map { |item| { model: item['sku_id'], quantity: item['amount'] }.with_indifferent_access } }
      end
      base_address_info = {
        full_name: package['full_name'],
        first_name: package['full_name'].split(' ').first,
        last_name: package['full_name'].split(' ').last,
        phone: package['cellphone'],
        address1: "#{package['address_attributes']['street']} #{package['address_attributes']['number']}",
        address2: package['address_attributes']['complement'],
        state: [{
          name: Commune.find_by(id: package['address_attributes']['commune_id']).try(:name)
        }]
      }

      seller_format = {
        package_destiny: define_destiny(package['destiny']),
        package_courier_for_client: define_courier(package['courier_for_client']),
        package_courier_selected: define_courier_selected(package['courier_for_client']),
        package_payable: define_payable(package['is_payable']),
        shipping_address: [base_address_info],
        billing_address: [base_address_info],
        customer: {
          email: package['email']
        },
        order_id: package['reference'],
        create_at: package['created_at'] || Time.current,
        status: [{
          id: 3,
          name: 'completed'
        }],
        items: ([inventory_activity_orders.call(package['inventory_activity']['inventory_activity_orders_attributes'])] unless package['inventory_activity'].blank?)
      }
      base_format(branch_office, package).merge(seller_format)
    end

    def self.api2cart_order(branch_office, package = {})
      inventory_activity_orders = lambda do |items|
        products = items.map do |item|
          {
            'model' => item['model'],
            'quantity' => item['quantity']
          }
        end
        { 'product' => products }
      end
      base_address_info = {
        full_name: package['full_name'],
        first_name: package['full_name'].split(' ').first,
        last_name: package['full_name'].split(' ').last,
        phone: package['cellphone'],
        address1: "#{package['address_attributes']['street']} #{package['address_attributes']['number']}",
        address2: package['address_attributes']['complement'],
        state: [{
          name: Commune.find_by(id: package['address_attributes']['commune_id']).try(:name)
        }]
      }

      seller_format = {
        package_destiny: define_destiny(package['destiny']),
        package_courier_for_client: define_courier(package['courier_for_client']),
        package_courier_selected: define_courier_selected(package['courier_for_client']),
        package_payable: define_payable(package['is_payable']),
        shipping_address: [base_address_info],
        billing_address: [base_address_info],
        customer: {
          email: package['email']
        },
        order_id: package['reference'],
        create_at: package['created_at'] || Time.current,
        status: [{
          id: 3,
          name: 'completed'
        }],
        items: ([inventory_activity_orders.call(package['inventory_activity']['inventory_activity_orders_attributes'])] unless package['inventory_activity'].blank?)
      }
      base_format(branch_office, package).merge(seller_format)
    end

    def self.base_format(branch_office, package = {})
      {
        seller: package['mongo_order_seller'],
        box_type: package['box_type'],
        company_id: branch_office.company.id,
        sent: define_sent(package['sent'])
      }
    end

    def self.define_courier(courier)
      return '' unless courier.present?

      case courier.downcase
      when 'chilexpress' then 'chilexpress'
      when 'chileparcels', 'chile_parcels' then 'chileparcels'
      when 'motopartner', 'moto_partner' then 'motopartner'
      when 'starken', 'starken-turbus' then 'starken'
      when 'correoschile', 'correos_chile', 'correos_de_chile' then 'correoschile'
      when 'dhl' then 'dhl'
      when 'muvsmart' then 'muvsmart'
      when 'bluexpress' then 'bluexpress'
      when 'shippify' then 'shippify'
      else
        ''
      end
    end

    def self.define_courier_selected(courier)
      courier.present? ? true : false
    end

    def self.define_payable(payable)
      payable.present? ? payable : false
    end

    def self.define_sent(sent)
      sent.presence || false
    end

    def self.define_destiny(destiny)
      destiny.present? ? destiny : 'Domicilio'
    end
  end
end
