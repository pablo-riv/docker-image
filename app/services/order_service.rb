class OrderService
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  # include Mongoid::Timestamps::Created
  include OrderTemplates
  include PackageTemplates

  field :seller_reference, type: String, default: ''
  field :customer_name, type: String, default: ''
  field :customer_email, type: String, default: ''
  field :customer_phone, type: String, default: ''
  field :shipping_data, type: Hash, default: {}
  field :shipping_data_complement, type: String, default: ''
  field :commune, type: Hash, default: {}
  field :day, type: DateTime, default: -> { Date.current }

  def self.today
    where(sent_at: (Time.current.beginning_of_day)..(Time.current.end_of_day))
  end

  def self.from(store = '')
    store.blank? ? OrderService.where('') : OrderService.where(seller: store)
  end

  def self.to_csv(current_account)
    SentOrdersJob.perform_now(current_account)
  end

  def self.download_packages_from(seller, current_account)
    marketplace = SellerConnection.new(seller)
    setting = current_account.entity_specific.settings.find { |s| s.service_id = 2 }
    marketplace.download_packages_from(setting, seller)
    where(company_id: setting.company_id)
  end

  def self.make_packages(params, current_account, skus, fulfillment, opit)
    params[:orders].map do |order|
      data = { order_id: order['_id']['$oid'],
               box_type: order['packing'],
               editable_deliver_info: {
                 street: order['shipping_data']['street'],
                 number: order['shipping_data']['number'],
                 complement: order['shipping_data_complement'],
                 commune: order['commune'].blank? ? nil : Commune.find_by(name: order['commune']['name']),
                 customer_name: order['customer_name'],
                 payable: order['package_payable'],
                 destiny: order['package_destiny'],
                 courier_for_client: order['package_courier_for_client'],
                 courier_selected: order['package_courier_selected'],
                 cbo: order['package_cbo']
               },
               current_account: current_account,
               skus: skus,
               has_fulfillment: fulfillment }
      deliver_order(data, opit)
    end
  end

  def self.deliver_order(args, opit)
    return 'Orden vacía' if args[:order_id].blank?

    order = OrderService.where(_id: args[:order_id])[0]
    return "Hubo problemas para actualizar la orden #{args[:order_id]} enviada" unless order.update_attributes(box_type: args[:box_type])

    message = 'Tienes configurado fulfillment, pero no encontramos tus SKU’s. Contactanos a soporte@shipit.cl para solucionar tu problema'
    return message if args[:skus].blank? && args[:has_fulfillment]

    if args[:has_fulfillment]
      stock_for_skus = confirm_stock(order, args[:skus])
      return "La órden #{order.order_id} contiene SKU's (#{stock_for_skus[:skus_without_stock]}) de los cuales no se tiene suficiente stock" unless stock_for_skus[:has_stock]
    end
    package_params =
      case order.seller
      when 'bootic' then package_template(bootic_package(order, args[:skus]), args[:editable_deliver_info], args[:current_account])
      when 'dafiti' then package_template(dafiti_package(order, args[:skus]), args[:editable_deliver_info], args[:current_account])
      when 'bsale' then package_template(bsale_package(order, args[:skus]), args[:editable_deliver_info], args[:current_account])
      when 'shopify' then package_template(shopify_package(order, args[:skus]), args[:editable_deliver_info], args[:current_account])
      when 'vtex' then package_template(vtex_package(order, args[:skus]), args[:editable_deliver_info], args[:current_account])
      when 'woocommerce', 'prestashop', 'opencart' then package_template(api2cart_package(order, args[:skus]), args[:editable_deliver_info], args[:current_account])
      end

    return package_params unless package_params.is_a?(Hash)

    transform_order_into_package(order, package_params, args[:current_account], args[:skus], args[:has_fulfillment], opit)
  end

  def self.transform_order_into_package(order, package_params, current_account, skus, fulfillment, opit)
    return 'La orden no contiene todos los campos requeridos para ser procesada, puedes editar la orden para completarla.' unless minimum_valid_format(package_params)

    package = Package.massive_create(packages: [package_params], account: current_account, branch_office: BranchOffice.find(package_params[:branch_office_id]), fulfillment: fulfillment, opit: opit)
    return package.first if package.first.is_a?(String)

    successfull_order(order, package.first, current_account, skus)
  end

  def self.successfull_order(order, package, _current_account, _skus)
    order.update_attributes(sent: true, package_id: package.id, sent_at: Time.current)
    package
  end

  def self.confirm_stock(order, skus)
    has_stock = true
    skus_without_stock = ''
    grouped_skus = case order.seller
                   when 'bootic'
                     order.items.each_with_object(Hash.new(0)) { |x, h| h[x['variant_sku'].to_s] += 1; }
                   when 'dafiti'
                     items = order.items['order_item'].is_a?(Array) ? order.items['order_item'] : [order.items['order_item']]
                     items.each_with_object(Hash.new(0)) { |x, h| h[x['sku'].to_s] += 1; }
                   when 'shopify'
                     order.items.each_with_object(Hash.new(0)) { |x, h| h[x['sku'].to_s] += x['quantity'];  }
                   when 'woocommerce', 'prestashop', 'opencart'
                     order.items.first['product'].each_with_object(Hash.new(0)) { |x, h| h[x['model'].to_s] += 1; }
                   end
    grouped_skus.each do |sku, quantity|
      found_sku = skus.find { |s| s['name'] == sku }
      if found_sku.blank? || found_sku['amount'].blank? || (found_sku['amount'].to_i - quantity) < 0
        has_stock = false
        skus_without_stock += "#{found_sku['name']} "
      end
    end
    { has_stock: has_stock, skus_without_stock: skus_without_stock }
  end

  def self.incoming_trackings(order, tracking, courier)
    raise 'Tracking vacio para asignar' if tracking.nil?

    service = eval("#{order.seller.capitalize}Service").new
    service.load_tracking(order, tracking, courier)
  end

  def self.incoming_statuses(order, status)
    raise 'Estado vacio para asignar' if status.nil?

    service = eval("#{order.seller.capitalize}Service").new
    service.order_status(order, status)
  end

  def self.process_dafiti_hook(params, account)
    return 200 unless params[:event] == 'onOrderCreated'

    client_id = Setting.fullit(account.entity_specific.id).configuration['fullit']['sellers'][0]['dafiti']['client_id']
    client_secret = Setting.fullit(account.entity_specific.id).configuration['fullit']['sellers'][0]['dafiti']['client_secret']
    SellerConnection.new('dafiti', client_id, client_secret).dafiti_single_order(params[:payload][:OrderId], account.entity_specific.id)
    200
  end

  def self.ready_to_deliver(search)
    dates = search[:from_date].to_date.beginning_of_day.to_s..search[:to_date].to_date.end_of_day.to_s
    total_orders = search[:seller_reference].present? ? OrderService.where(company_id: search[:company_id], sent: false, seller_reference: search[:seller_reference]) : OrderService.where(company_id: search[:company_id], sent: false).between(day: dates)
    total_orders = total_orders.select { |order| order.seller_order_status == 'pending' || order.seller_order_status == 'invoiced' }
    filters = total_orders.map { |order| next unless order.try(:shipping_lines).present?; order.shipping_lines[0]['title'] }.uniq

    oss = total_orders
    if search[:filter].present? && !search[:filter].downcase.include?('todos') && !search[:seller_reference].present?
      oss = total_orders.select { |os| os.shipping_lines[0]['title'].try(:downcase) == search[:filter].downcase }
      total_orders = oss
    end
    oss = oss.sort_by { |o| o.created || (DateTime.current - 15.days) }.reverse
    { oss: Kaminari.paginate_array(oss).page(search[:page]).per(search[:per]).map(&:serialize_data!), total_orders: total_orders.count, filters: filters }
  end

  def self.minimum_valid_format(package_params)
    valid = true
    package_params.each do |attr_mame, value|
      case attr_mame.to_s
      when 'full_name' then valid = false if value.blank?
      when 'reference' then valid = false if value.blank?
      when 'items_count' then valid = false if value.blank? || value.zero?
      when 'shipping_type' then valid = false if value.blank?
      when 'destiny' then valid = false if value.blank?
      when 'packing' then valid = false if value.blank?
      when 'commune_id' then valid = false if value.blank? || value.zero?
      when 'number' then valid = false if value.blank?
      when 'street' then valid = false if value.blank?
      when 'address_attributes' then valid = minimum_valid_format(value)
      end
    end
    valid
  end

  def self.extract_value_by(object, split_by, chain)
    chain.split(split_by).map do |partial|
      partial_value = object[partial] unless object.blank?
      object = partial_value.class.name == 'Array' ? partial_value[0] : partial_value
      if partial == 'state'
        object = object['name'] unless object.blank?
      end
    end
    object
  end

  def self.invert_package_to_order(branch_office, package = {})
    order =
      case package['mongo_order_seller'].try(:downcase)
      when 'shopify' then shopify_order(branch_office, package) # here needs to add a flag
      when 'prestashop' then api2cart_order(branch_office, package)
      when 'woocommerce' then woocommerce_order(branch_office, package)
      end

    raise 'Seller no encontrado' if order.blank?

    SellerConnection.new(package['mongo_order_seller'].try(:downcase)).find_or_create_order(order: order, perform: 'later', version: 2)
  end

  def reference
    package_id.blank? ? seller_reference : Package.find(package_id).reference
  end

  def set_seller_reference
    reference =
      case seller
      when 'bootic' then code
      when 'dafiti' then order_number
      when 'bsale' then order_id
      when 'shopify' then name
      when 'vtex' then seller_reference
      when 'woocommerce', 'prestashop', 'opencart' then order_id
      else
        'No se tiene registro'
        end
  end

  def created
    case seller
    when 'bootic' then created_on.to_datetime
    when 'dafiti' then created_at.to_datetime
    when 'bsale' then Time.at(shipping_date).to_datetime
    when 'shopify' then created_at.to_datetime
    when 'vtex' then vtex_created
    when 'woocommerce', 'prestashop', 'opencart' then (status.first['history'].first['history'].first['modified_time'].to_datetime unless status.first['history'].blank? || status.first['history'].first['history'].blank?) || self['create_at'].try(:to_datetime)
    else
      'No se tiene registro'
    end
  end

  def seller_order_status
    prestashop_accepted_statuses = [2, 3]
    woocommerce_accepted_statuses = ['completed', 'processing', 'completado', 'procesando', 'on hold', 'en espera']
    current_status =
      case seller
      when 'bootic' then status == 'closed' ? 'pending' : 'not_pending'
      when 'dafiti' then statuses.is_a?(Array) ? statuses.last['status'] : statuses['status']
      when 'bsale' then status
      when 'shopify' then fulfillment_status == 'pending' && financial_status == 'paid' ? 'pending' : 'not_pending'
      when 'woocommerce' then woocommerce_accepted_statuses.include?(status.last['name'].try(:downcase)) || status.last['id'].try(:downcase) == 'wc-completed' ? 'pending' : 'not_pending'
      when 'prestashop' then prestashop_accepted_statuses.include?(status.last['id'].try(:to_i)) ? 'pending' : 'not_pending'
      when 'opencart' then status.last['name']
      when 'vtex' then status
      end
    current_status.try(:downcase)
  end

  def package_created
    package_id.blank? ? '' : Package.find(package_id).created_at
  end

  def skus
    return '' if seller == 'bsale' || items.blank?

    case seller
    when 'bootic' then bootic_skus
    when 'dafiti' then dafiti_skus
    when 'shopify' then shopify_skus
    when 'woocommerce', 'prestashop', 'opencart' then api2cart_skus
    else
      'No se tiene registro'
    end
  end

  def shopify_skus
    str = ''
    items.map.with_index { |item, index| index == (items.count - 1) ? (str += item['sku'].to_s) : (str += "#{item['sku']}; ") }
    str
  end

  def bootic_skus
    str = ''
    items.map.with_index { |item, index| index == (items.count - 1) ? (str += item['variant_sku'].to_s) : (str += "#{item['variant_sku']}; ") }
    str
  end

  def dafiti_skus
    str = ''
    if items['order_item'].class.name != 'Array'
      str = items['order_item']['sku']
    else
      items['order_item'].map.with_index { |item, index| index == (items['order_item'].count - 1) ? (str += item['sku'].to_s) : (str += "#{item['sku']}; ") }
    end
    str
  end

  def api2cart_skus
    str = ''
    items.first['product'].map.with_index do |item, index|
      next if item['model'].blank?

      str += if index == (items.first['product'].count - 1)
               item['model'].to_s
             else
               "#{item['model']}; "
             end
    end
    str
  end

  def item_sku(index)
    return if seller == 'bsale'

    case seller
    when 'bootic' then items[index]['variant_sku']
    when 'dafiti' then skus.delete(';', '').split(' ')[index]
    when 'shopify' then items[index]['sku']
    when 'api2cart' then items[index]['product'].last['model']
    else
      ''
    end
  end

  def item_ids
    return '' if seller != 'dafiti' || items.blank?

    str = ''
    if items['order_item'].class.name != 'Array'
      str = items['order_item']['order_item_id']
    else
      items['order_item'].map.with_index { |item, index| index == (items['order_item'].count - 1) ? (str += item['order_item_id'].to_s) : (str += "#{item['order_item_id']}; ") }
    end
    str
  end

  def set_customer_name
    new_customer_name =
      case seller
      when 'bootic' then contact['name']
      when 'dafiti' then "#{customer_first_name} #{customer_last_name}"
      when 'bsale' then "#{client['first_name']} #{client['last_name']}"
      when 'shopify' then self['address_shipping']['name'].to_s unless self['address_shipping'].blank?
      when 'prestashop', 'opencart' then ("#{shipping_address.last['first_name']} #{shipping_address.last['last_name']}" unless shipping_address.blank?)
      when 'woocommerce' then shipping_address.last['full_name']
      when 'vtex' then customer_name
      else
        'No se tiene registro'
      end
  end

  def set_customer_email
    new_customer_email =
      case seller
      when 'bootic' then contact[:email] || contact['email'] unless contact.blank?
      when 'dafiti' then address_shipping['customer_email'] unless address_shipping.blank?
      when 'bsale' then ''
      when 'shopify' then email
      when 'woocommerce', 'prestashop', 'opencart'
        if !billing_address.blank? && !billing_address.last['email'].blank?
          billing_address.last['email']
        elsif !shipping_address.blank? && !shipping_address.last['email'].blank?
          shipping_address.last['email']
        else
          customer['email'] unless customer.blank? || customer.is_a?(Array)
        end
      when 'vtex' then customer_email
      else
        'No se tiene registro'
      end
  end

  def set_customer_phone
    new_customer_phone =
      case seller
      when 'bootic' then contact[:phone_number] || contact['phone_number'] unless contact.blank?
      when 'dafiti' then address_shipping['phone'].blank? ? address_shipping['phone2'] : address_shipping['phone'] unless address_shipping.blank?
      when 'bsale' then ''
      when 'shopify' then address_shipping['phone'] unless address_shipping.blank?
      when 'woocommerce', 'prestashop', 'opencart'
        if !billing_address.blank? && !billing_address.last['phone'].blank?
          billing_address.last['phone']
        elsif !shipping_address.blank? && !shipping_address.last['phone'].blank?
          shipping_address.last['phone']
        else
          customer['phone'] unless customer.blank? || customer.is_a?(Array)
        end
      when 'vtex' then customer_phone
      else
        'No se tiene registro'
      end
  end

  def shipping_name
    case seller
    when 'bootic' then contact['name']
    when 'dafiti' then "#{address_shipping['first_name']} #{address_shipping['last_name']}"
    when 'bsale' then customer_name
    when 'shopify' then address_shipping['name'] unless address_shipping.blank?
    when 'prestashop', 'opencart' then "#{shipping_address.last['first_name']} #{shipping_address.last['last_name']}"
    when 'woocommerce' then shipping_address.last['full_name']
    when 'vtex' then customer_name
    else
      'No se tiene registro'
    end
  end

  # integrations versions: 1 = api2cart or any download methods
  # integrations versions: 2 or later = any of plugins by shipit
  def set_shipping_data(version = 1)
    new_shipping_data =
      case seller
      when 'bootic' then bootic_shipping_data
      when 'dafiti' then dafiti_shipping_data
      when 'bsale' then bsale_shipping_data
      when 'shopify' then shopify_shipping_data(version)
      when 'woocommerce', 'prestashop', 'opencart' then api2cart_shipping_data
      when 'vtex' then shipping_data
      else
        'No se tiene registro'
      end
  end

  def bootic_shipping_data
    # {
    #   street: address[:street].gsub(/[0-9]/, '#').strip.split('#').first,
    #   number: address[:street].gsub(/[^0-9]/, ' ').strip.split(' ').first.blank? ? address[:street_2].gsub(/[^0-9]/, ' ').strip.split(' ').first : address[:street].gsub(/[^0-9]/, ' ').strip.split(' ').first
    # }
    number = (address[:street].scan(/[[a-zA-Z],\s*,\,]\d{1,10}/).first || '').gsub(/[\s,\,[a-zA-Z]]/, '')
    {
      street: (address[:street].split(number).first || '').gsub(',', '').strip,
      number: number
    }
  end

  def dafiti_shipping_data
    posible_address = address_shipping['address1'] || address_shipping['address2']
    {
      street: posible_address.gsub(/[^aA-zZ]/, ' ').strip,
      number: posible_address.gsub(/[^0-9]/, '').strip
    }
  end

  def bsale_shipping_data
    {
      street: address.blank? ? nil : address.gsub(/[^aA-zZ]/, ' ').strip,
      number: address.blank? ? nil : address.gsub(/[^0-9]/, '').strip
    }
  end

  # Monkey patch applied to continues lines.
  # please take a look and please get out of here.
  def compose_address_format
    regex = /[[a-zA-Z]\s*|\W]\d{1,10}/
    clean_regex = /[^0-9]/
    address_company = address_shipping['company'] || ''
    shopify_street = address_shipping['address1'] || ''
    shopify_complement = address_shipping['address2'] || ''
    if shopify_street.match(regex)
      number = shopify_street.scan(regex)[0].gsub(clean_regex, '')
      street = shopify_street.split(number)[0].gsub(',', '').strip
      complement = shopify_street.split(number).size > 1 ? shopify_street.split(number)[1].gsub(',', '').strip : shopify_complement
    elsif address_company.match(regex)
      number = address_company.scan(regex)[0].gsub(clean_regex, '')
      street = address_company.split(number)[0].gsub(',', '').strip
      complement = address_company.split(number).size > 1 ? address_company.split(number)[1].gsub(',', '').strip : shopify_complement
    else
      number = shopify_street
      street = address_company
      complement = shopify_complement
    end

    { street: street, number: number, complement: complement }
  end

  def shopify_shipping_data(version = 1)
    if version == 1
      { street: compose_address_format[:street], number: compose_address_format[:number] }
    else
      { street: address_shipping['address1'], number: address_shipping['number'] }
    end
  end

  def api2cart_shipping_data
    seller_data_fields_config = Setting.fullit(company_id).seller_configuration(seller).values[0]['fields']
    if seller_data_fields_config.blank? || seller_data_fields_config['number'].blank? || seller_data_fields_config['street'].blank?
      posible_number = shipping_address.last['address1'].gsub(/[^0-9]/, ' ').strip.split(' ').first unless shipping_address.blank? || shipping_address.last['address1'].blank?
      posible_address = shipping_address.last['address1'].split(posible_number).first unless shipping_address.blank? || shipping_address.last['address1'].blank?
      second_posible_number = billing_address.last['address2'].gsub(/[^0-9]/, ' ').strip.split(' ').first unless billing_address.blank? || billing_address.last['address2'].blank?
      second_posible_address = billing_address.last['address1'].split(second_posible_number).first unless billing_address.blank? || billing_address.last['address1'].blank?
    else
      posible_number = seller_data_fields_config['number'].map { |partial| OrderService.extract_value_by(self, '&', partial) }.join(' ').gsub(/[^0-9]/, ' ').strip.split(' ').first
      posible_address = seller_data_fields_config['street'].map { |partial| OrderService.extract_value_by(self, '&', partial) }.join(' ').split(posible_number).first
    end
    {
      street: posible_address || second_posible_address,
      number: posible_number || second_posible_number
    }
  end

  def set_shipping_data_complement
    new_shipping_data_complement =
      case seller
      when 'bootic' then (address['street_2'].gsub(%r{<br/>}, '').blank? ? address['street'].split(bootic_shipping_data[:number]).second : address['street_2'].gsub(%r{<br/>}, '')) unless address['street_2'].blank?
      when 'dafiti' then address_shipping['address2'].gsub(%r{<br/>}, ' ').gsub(%r{Dpto/Casa/Of: }, '')
      when 'bsale' then address
      when 'shopify' then compose_address_format[:complement] unless address_shipping.blank?
      when 'woocommerce', 'prestashop', 'opencart' then api2cart_data_complement
      when 'vtex' then shipping_data_complement
      else
        'No se tiene registro'
      end
  end

  def api2cart_data_complement
    seller_data_fields_config = Setting.fullit(company_id).seller_configuration(seller).values[0]['fields']
    if seller_data_fields_config.blank? || seller_data_fields_config['complement'].blank?
      "#{shipping_address.last['address1'].split(shipping_address.last['address1'].gsub(/[^0-9]/, ' ').strip.split(' ').first).last} #{shipping_address.last['address2']}" unless shipping_address.blank? || shipping_address.last['address1'].blank?
    else
      seller_data_fields_config['complement'].map { |partial| OrderService.extract_value_by(self, '&', partial) }.join(' ').split(api2cart_shipping_data[:number]).last
    end
  end

  def total_price
    case seller
    when 'bootic' then total
    when 'dafiti' then price
    when 'bsale' then document['total_amount']
    when 'shopify' then self['total_price']
    when 'woocommerce', 'prestashop', 'opencart' then (respond_to?(:totals) ? totals.last['total'] : 0)
    else
      0
    end
  end

  def set_commune
    new_commune =
      case seller
      when 'bootic' then Commune.find_by(name: address[:locality_name].mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').upcase.to_s)
      when 'dafiti' then Commune.find_by(name: address_shipping['city'].mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').upcase.to_s)
      when 'bsale' then Commune.find_by(name: municipality.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').upcase.to_s)
      when 'shopify' then Commune.find_by(name: address_shipping['city'].mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').upcase.to_s.strip) unless address_shipping.blank? || address_shipping['city'].blank?
      when 'woocommerce' then Commune.find_by(name: billing_address[0]['state'][0]['name'].mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').upcase.to_s.strip) unless billing_address[0]['state'][0]['name'].blank?
      when 'prestashop', 'opencart' then api2cart_extract_commune
      when 'vtex' then Commune.find_by(name: commune['name'])
      else
        'No se tiene registro'
      end
    new_commune.attributes unless new_commune.blank?
  end

  def extract_commune(object_to_iterate)
    searching_fields = %w[city state zip]
    return [] if object_to_iterate.blank?

    object_to_iterate.map do |params|
      next if params.second.blank? || (params.first != 'state' && !params.second.is_a?(String)) || !searching_fields.include?(params.first)

      to_filter = params.second
      to_filter = params.second.last['name'] if params.first == 'state'
      Commune.find_by(name: to_filter.try(:upcase))
      # posible_commune = to_filter.split(' ').last.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').upcase.to_s
      # Commune.where("CONCAT(' ', name, ' ') LIKE '% #{posible_commune} %'").first
    end
  end

  def api2cart_extract_commune
    seller_data_fields_config = Setting.fullit(company_id).seller_configuration(seller).values[0]['fields']
    if seller_data_fields_config.blank? || seller_data_fields_config['commune'].blank?
      Commune.find_by(name: shipping_address.last['state'].last['name'].mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').upcase.to_s) unless shipping_address.blank? || shipping_address.last['state'].blank?
      # extract_commune(shipping_address.last).compact.first || extract_commune(billing_address.last).compact.first
    else
      posible_commune = seller_data_fields_config['commune'].map { |partial| OrderService.extract_value_by(self, '&', partial) }.compact.first
      processed = (posible_commune || 'nothing').mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').upcase.to_s
      Commune.find_by(name: processed) || Commune.where("CONCAT(' ', name, ' ') LIKE '% #{processed} %'").first
    end
  end

  def dafiti_order_update_status(tracking, status)
    puts items['order_item'].to_s.yellow
    order_items = items['order_item'].class.name == 'Array' ? items['order_item'] : [items['order_item']]
    new_items = []
    order_items.each do |item|
      new_item = item
      new_item['tracking_code'] = tracking
      new_item['status'] = status
      new_items << new_item
    end
    update_attributes(statuses: { status: status }, items: { 'order_item': new_items })
  end

  def serialize_data!
    serializable_hash(methods: %i[seller_reference created seller_order_status skus])
  end

  # integrations versions: 1 = api2cart or any download methods
  # integrations versions: 2 or later = any of plugins by shipit
  def set_base_info(version = 2)
    update(seller_reference: set_seller_reference,
           customer_name: set_customer_name,
           customer_email: set_customer_email,
           customer_phone: set_customer_phone,
           shipping_data: set_shipping_data(version),
           shipping_data_complement: set_shipping_data_complement,
           commune: set_commune)
  end
end
