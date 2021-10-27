module OrderTemplates
  extend ActiveSupport::Concern

  included do
    def self.bootic_package(order, skus)
      unless skus.blank?
        grouped_skus_arr = []
        order.items.inject(Hash.new(0)) { |h,x| h[x['variant_sku'].to_s]+=x['units'].try(:to_i); h }.each { |key, value| grouped_skus_arr.push({key.to_s => value}) }
        inventory_activity_orders = self.generate_hash_of_hashes(grouped_skus_arr, skus)
      end
      {
        email: order.customer_email,
        cellphone: order.customer_phone,
        reference: order.seller_reference,
        comments: 'Bootic',
        box_type: order.box_type,
        items: order.items.count,
        mongo_order_id: order.id,
        mongo_order_seller: 'bootic',
        inventory_activity: inventory_activity_orders
      }
    end

    def self.dafiti_package(order, skus)
      unless skus.blank?
        grouped_skus_arr = []
        items = order.items['order_item'].is_a?(Array) ? order.items['order_item'] : [order.items['order_item']]
        items.inject(Hash.new(0)) { |h, x| h[x['sku'].to_s]+=1; h }.each { |key, value| grouped_skus_arr.push({key.to_s => value}) }
        inventory_activity_orders = generate_hash_of_hashes(grouped_skus_arr, skus)
      end
      {
        'email': order.customer_email,
        'cellphone': order.customer_phone,
        'reference': order.seller_reference,
        'comments': 'Dafiti',
        'box_type': order.box_type,
        'items': order.items_count.to_i,
        'mongo_order_id': order.id,
        'mongo_order_seller': 'dafiti',
        'inventory_activity': inventory_activity_orders
      }
    end

    def self.bsale_package(order, skus)
      unless skus.blank?
        grouped_skus_arr = []
        items = order.items['order_item'].is_a?(Array) ? order.items['order_item'] : [order.items['order_item']]
        items.inject(Hash.new(0)) { |h, x| h[x['sku'].to_s]+=1; h }.each { |key, value| grouped_skus_arr.push({key.to_s => value}) }
        inventory_activity_orders = generate_hash_of_hashes(grouped_skus_arr, skus)
      end
      {
        'email': order.customer_email,
        'cellphone': order.customer_phone,
        'reference': order.seller_reference,
        'comments': 'Bsale',
        'box_type': order.box_type,
        'items': 1,
        'mongo_order_id': order.id,
        'mongo_order_seller': 'bsale',
        'inventory_activity': inventory_activity_orders
      }
    end

    def self.shopify_package(order, skus)
      unless skus.blank?
        grouped_skus_arr = []
        order.items.inject(Hash.new(0)) { |h,x| h[x['sku'].to_s]+=x['quantity']; h }.each { |key, value| grouped_skus_arr.push({key.to_s => value}) }
        inventory_activity_orders = generate_hash_of_hashes(grouped_skus_arr, skus)
      end
      {
        'email': order.customer_email,
        'cellphone': order.customer_phone,
        'reference': order.seller_reference,
        'comments': 'Shopify',
        'box_type': order.box_type,
        'items': order.items.blank? ? 1 : order.items.count,
        'mongo_order_id': order.id,
        'mongo_order_seller': 'shopify',
        'inventory_activity': inventory_activity_orders,
        'seller_order_id': order.order_id
      }
    end

    def self.api2cart_package(order, skus)
      unless skus.blank?
        grouped_skus_arr = []
        order.items.first['product'].inject(Hash.new(0)) { |h,x| h[x['model'].to_s]+=x['quantity']; h }.each { |key, value| grouped_skus_arr.push({key.to_s => value}) }
        inventory_activity_orders = self.generate_hash_of_hashes(grouped_skus_arr, skus)
      end
      {
        'email': order.customer_email,
        'cellphone': order.customer_phone,
        'reference': order.seller_reference,
        'comments': 'Api2Cart',
        'box_type': order.box_type,
        'items': order.items.blank? ? 1 : order.items.count,
        'mongo_order_id': order.id,
        'mongo_order_seller': order.seller,
        'inventory_activity': inventory_activity_orders
      }
    end

    def self.vtex_package(order, skus)
      unless skus.blank?
        grouped_skus_arr = []
        order.items.inject(Hash.new(0)) { |h,x| h[x['sku'].to_s]+=x['quantity']; h }.each { |key, value| grouped_skus_arr.push({key.to_s => value}) }
        inventory_activity_orders = generate_hash_of_hashes(grouped_skus_arr, skus)
      end
      {
        'email': order.customer_email,
        'cellphone': order.customer_phone,
        'reference': order.seller_reference,
        'comments': 'VTex',
        'box_type': order.box_type,
        'items': order.items.blank? ? 1 : order.items.count,
        'mongo_order_id': order.id,
        'mongo_order_seller': 'vtex',
        'seller_order_id': order.order_id,
        'inventory_activity': inventory_activity_orders
      }
    end

    def self.generate_hash_of_hashes(array, skus)
      obj = []
      (0..(array.count - 1)).each_with_index { |value, index| found_sku = skus.find{ |s| s['name'] == array[index].keys[0] }; obj << { sku_id: found_sku['id'], amount: array[index].values[0], warehouse_id: found_sku['warehouse_id'] } }
      { 'inventory_activity_orders_attributes': obj }
    end

    def self.package_template(template, editable_info, current_account)
      return "Aún no realizamos envíos a esta comuna: #{editable_info[:commune]}" if editable_info[:commune].blank? || editable_info[:commune].id.zero?

      street = editable_info[:street]
      number = editable_info[:number]
      return 'Número de Dirección vacío' if editable_info[:number].blank?
      return 'Error de formato, debes corroborar que la orden posea toda la información necesaria' if template.class.name != 'Hash'
      {
        'pickup_id': '',
        'branch_office_id': current_account.current_branch_office.id,
        'address_attributes': {
          'commune_id': editable_info[:commune][:id],
          'street': editable_info[:street],
          'number': editable_info[:number],
          'complement': editable_info[:complement],
          'coords': {
            'latitude': 0,
            'longitude': 0
          }
        },
        'platform': 3,
        'full_name': editable_info[:customer_name],
        'email': template[:email],
        'cellphone': template[:cellphone],
        'length': 10,
        'width': 10,
        'height': 10,
        'weight': 1,
        'approx_size': 'Pequeño (10x10x10cm)',
        'destiny': editable_info[:destiny] || 'Domicilio',
        'reference': template[:reference],
        'is_payable': editable_info[:payable] || false,
        'is_available': true,
        'comments': template[:comments],
        'items_count': template[:items],
        'shipping_type': 'Normal',
        'packing': 'Sin Empaque', # business rule applied 04/01/2019
        'courier_branch_office_id': template[:cbo].try(:to_i) || 0,
        'mongo_order_id': template[:mongo_order_id],
        'mongo_order_seller': template[:mongo_order_seller],
        'inventory_activity': template[:inventory_activity],
        'courier_for_client': editable_info[:courier_for_client],
        'courier_selected': editable_info[:courier_selected],
        'seller_order_id': template[:seller_order_id]
      }.with_indifferent_access
    end
  end
end
