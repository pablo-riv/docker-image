class Setting < ApplicationRecord
  DEFAULT_COUNTRY = 'cl'.freeze

  after_create :template_configuration
  before_update :verify_configuration, unless: :denied_service?
  after_update :publish_configuration
  ## RELATIONS
  belongs_to :service
  belongs_to :company

  has_paper_trail ignore: [:updated_at]

  scope :by_company, ->(id) { where(company_id: id) }
  scope :by_service, ->(id) { where(service_id: id) }

  attr_accessor :courier_id, :is_default_courier, :service_key, :service_password

  # DELEGATES
  delegate :name, to: :service, prefix: true, allow_nil: true

  def self.allowed_attributes
    [:email_notification, :email_alert, :is_default_price, :service_key, :service_password, "configuration": { "notification": { "buyer": {}, "client": {} } } ]
  end

  def self.opit(company_id)
    find_by(service_id: 1, company_id: company_id)
  end

  def self.fullit(company_id)
    find_by(service_id: 2, company_id: company_id)
  end

  def self.pp(company_id)
    find_by(service_id: 3, company_id: company_id)
  end

  def self.fulfillment(company_id)
    find_by(service_id: 4, company_id: company_id)
  end

  def self.sd(company_id)
    find_by(service_id: 5, company_id: company_id)
  end

  def self.notification(company_id)
    find_by(service_id: 6, company_id: company_id)
  end

  def self.printers(company_id)
    find_by(service_id: 7, company_id: company_id)
  end

  def self.analytics(company_id)
    find_by(service_id: 8, company_id: company_id)
  end

  def self.automatization(company_id)
    find_by(service_id: 9, company_id: company_id)
  end

  def self.labelling(company_id)
    find_by(service_id: 10, company_id: company_id)
  end

  def self.import(params)
    self.transaction do
      csv = params[:CXP_prices] || params[:STK_prices] || params[:CC_prices]
      prices = []
      courier_name = csv.original_filename.split('_').first.downcase
      CSV.foreach(csv.path, headers: true) do |row|
        price = row.to_hash
        raise ActiveRecord::Rollback, '' unless price['region'] && price['destino'] && price['plazo_estimado'] && price['kg_adicional']
        price_by_size = price.keys.each_with_index.map { |key, i| { "#{key}": price[key] } if i > 2 }.compact
        keys = []
        (0..price.keys.count).each_with_index { |i| keys.push(price.keys[i]) if i > 2 && i <= price.keys.count }
        keys.each_with_index { |name, _index| price.delete(name) }
        courier_name = courier_name == 'correos' ? "#{courier_name}chile" : courier_name
        commune = Commune.find_by("couriers_availables ->> ? = ?", courier_name, price['destino'].strip)
        next if commune.nil?
        price['region'] = commune.region_id.to_s
        price['precios'] = price_by_size
        price['destino'] = price['destino'].strip
        price['plazo_estimado'] = price['plazo_estimado'].strip
        prices.push(price)
      end
      return { prices: prices, courier: courier_name }
    end
  rescue => e
    puts "😭  #{e.message}"
  end

  def self.save_courier_prices(data = {}, setting = {}, service = {})
    return false if data.nil? || setting.nil? || service.nil?
    setting.configuration['opit']['couriers'].each do |courier|
      courier[setting.courier_name(data[:courier])]['destinies'] = data[:prices] if courier.keys.first == setting.courier_name(data[:courier])
    end
    setting.put_json_file(data[:courier]) if setting.update_columns(configuration: setting.configuration)
  end

  def self.send_notification_of(company, state)
    return if state.blank? || company.blank?

    configuration = notification(company).configuration['notification']['buyer']['mail']
    { 'state' => configuration['state'][state], 'cc' => configuration['cc'] }
  end

  def self.notification_configuration_for(company)
    return unless company.present?

    notification(company).configuration['notification']
  end

  def whatsapp_configuration_for(company, state)
    return unless state.present? || company.present?

    configuration['notification']['buyer']['whatsapp']['state'][state]
  end

  def email_configuration_for(company, state)
    return unless state.present? || company.present?

    configuration['notification']['buyer']['mail']['state'][state]
  end

  def put_json_file(courier)
    name = courier_name(courier)
    data = [configuration['opit']['couriers'].select { |c| c.keys[0] == name }[0][name]]
    File.open("public/#{courier}_json.json", 'w') do |f|
      f.write(data.to_json)
    end
  end

  def courier_name(courier)
    case courier
    when 'chilexpress' then 'cxp'
    when 'starken' then 'stk'
    when 'correos' then 'cc'
    when 'dhl' then 'dhl'
    when 'muvsmart' then 'muvsmart'
    when 'chileparcels' then 'chileparcels'
    when 'motopartner' then 'motopartner'
    when 'bluexpress' then 'bluexpress'
    when 'shippify' then 'shippify'
    end
  end

  def self.inverse_courier_name(courier)
    case courier
    when 'cxp' then 'chilexpress'
    when 'stk' then 'starken'
    when 'cc' then 'correoschile'
    when 'dhl' then 'dhl'
    when 'muvsmart' then 'muvsmart'
    when 'chileparcels' then 'chileparcels'
    when 'motopartner' then 'motopartner'
    when 'bluexpress' then 'bluexpress'
    when 'shippify' then 'shippify'
    end
  end

  def self.get_shipment_couriers_v2(current_account, commune_id)
    company_id = current_account.entity.actable_type.downcase == 'company' ? current_account.entity.specific.id : current_account.entity.specific.company.id
    settings_json = Setting.opit(company_id).configuration['opit']['couriers']
    couriers_availables_for_communes = Commune.find_by(id: commune_id).try(:couriers_availables) || {}
    couriers_availables = {}
    keys = []

    settings_json.each do |values|
      values.each do |key, value|
        couriers_availables[Setting.inverse_courier_name(key)] = couriers_availables_for_communes[Setting.inverse_courier_name(key)] if value['available']
      end
    end

    couriers_availables.compact
  end

  def self.get_shipment_couriers_v3(current_account, origin_commune_id, destiny_commune_id)
    if current_account.current_company.backoffice_couriers_enabled?
      Coverages::Courier.new({ account: current_account }).availables_by_origin_and_destiny(1, origin_commune_id, destiny_commune_id)
    else
      {
        from: Setting.get_shipment_couriers_v2(current_account, origin_commune_id),
        to: Setting.get_shipment_couriers_v2(current_account, destiny_commune_id)
      }
    end
  end

  def denied_service?
    service.name == "notification"
  end

  def printer_service?
    service_id == 7
  end

  def printer_way
    configuration['printers']['kind_of_print']
  end

  def algorithm
    configuration['opit']
  end

  def template_configuration
    configuration = define_base_config
    update_columns(configuration: configuration)
  end

  def define_base_config
    base_params = { key: '', secret_key: '', price: '' }
    configuration =
      case service_id
      when 1 then { opit: base_params.merge(opit_template)}
      when 2 then { fullit: base_params.merge(sellers: template_sellers) }
      when 3 then { pp: base_params.merge(pick_and_pack_template) }
      when 4 then { fulfillment: base_params }
      when 5 then { sd: base_params }
      when 6 then { notification: base_params.merge(default_template_notification) }
      when 7 then { printers: base_params.merge(default_template_printers) }
      when 8 then { analytics: default_template_analytics }
      when 9 then { automatizations: base_params.merge(template_automatizations) }
      end
  end

  def verify_configuration
    configuration[service.name.to_s] = service_key
    configuration[service.name.to_s] = service_password
  end

  def seller_configuration(seller_name)
    return if service_id != 2

    HashWithIndifferentAccess.new(configuration['fullit']['sellers'].find { |seller| seller[seller_name] })
  end

  def set_webhooks(settings)
    case service_id
    when 3
      configuration['pp']['webhook']['package']['url'] = settings['configuration']['pp']['webhook']['package']['url'].strip
      configuration['pp']['webhook']['pickup']['url'] = settings['configuration']['pp']['webhook']['pickup']['url'].strip if settings['configuration']['pp']['webhook'].keys.size > 1
    when 4
      configuration['fulfillment']['webhook']['sku']['url'] = settings['configuration']['fulfillment']['webhook']['sku'].strip
    end
    update_columns(configuration: configuration)
  end

  def integrate_seller(params)
    seller_name = params[:seller]
    marketplace = SellerConnection.new(seller_name, params[:client_id], params[:client_secret]) unless (params[:client_id].blank? || params[:client_secret].blank?) && !%w(bootic woocommerce).include?(seller_name)
    configuration['fullit']['sellers'].each do |seller|
      next unless seller_name == seller.keys.first
      seller[seller_name]['authorization_token'] = params[:authorization_token] if seller_name == 'bootic' && params[:authorization_token].present?
      seller[seller_name]['access_token'] = marketplace.bootic_token(self, params[:authorization_token]) if seller_name == 'bootic' && params[:authorization_token].present?
      seller[seller_name]['client_id'] = params[:client_id]
      seller[seller_name]['client_secret'] = params[:client_secret]
      seller[seller_name]['automatic'] = params[:automatic]
      seller[seller_name]['automatic_hour'] = params[:hour]
      seller[seller_name]['automatic_packing'] = params[:packing]
      seller[seller_name]['automatic_delivery'] = params[:automatic_delivery]
      seller[seller_name]['show_shipit_checkout'] = params[:show_shipit_checkout]
      seller[seller_name]['store_name'] = params[:store_name] if ['shopify', 'vtex'].include?(seller_name)
      seller[seller_name]['fields'] = params[:fields] if seller_name == 'woocommerce' || seller_name == 'prestashop'
    end
    update_columns(configuration: configuration)
    return true if params[:client_id].blank? && seller_name != 'bootic'
    puts '💪 haciendo primera descarga de informacion...'.yellow
    seller_data = [{ setting: self, name: seller_name, client_id: params[:client_id], client_secret: params[:client_secret], store_name: params[:store_name]}]
    marketplace.dafiti_create_webhook(seller_data.first) if seller_name == 'dafiti' && !params[:client_id].blank?
    return true unless %w(bootic shopify).include?(seller_name)

    Rails.env.production? ? DownloadSellerOrdersJob.perform_later(seller_data.compact, company, (DateTime.current - 1.months).to_s, DateTime.current.to_s) : DownloadSellerOrdersJob.perform_now(seller_data.compact, company, (DateTime.current - 1.months).to_s, DateTime.current.to_s)
    true
  end

  def courier_tcc(courier_name)
    courier = configuration['opit']['couriers'].find { |object| object.keys.first.downcase == Courier.name_to_achronim(courier_name.downcase) }
    courier[courier.keys.first]
  end

  def update_courier_configuration(data)
    configuration['opit']['couriers'].map do |object|
      courier = data['couriers'].select { |courier_object| courier_object.keys[0] == object.keys[0] }.first
      object[object.keys[0]].merge!(courier[courier.keys[0]].as_json)
    end
    configuration['opit']['algorithm'] = data['algorithm']
    configuration['opit']['algorithm_days'] = data['algorithm_days']
    update_columns(configuration: configuration)
  end

  def sync_seller_orders(from_date, to_date)
    sellers = configuration['fullit']['sellers'].map do |seller|
      name = seller.keys.first
      next if seller[name]['client_id'].blank? && name != 'bootic'
      next if name == 'bootic' && seller[name]['authorization_token'].blank?
      {
        setting: self,
        name: seller.keys.first,
        client_id: seller[name]['client_id'],
        client_secret: seller[name]['client_secret'],
        store_name:  seller[name]['store_name']
      }
    end
    Rails.env.production? ? DownloadSellerOrdersJob.perform_later(sellers.compact, company, from_date, to_date) : DownloadSellerOrdersJob.perform_now(sellers.compact, company, from_date, to_date)
  end

  def publish_configuration
    Publisher.publish('settings', serializable_hash(include: [:company, :service])) if service_id == 3
  end

  def fulfillment_notification
    configuration['notification']['client']['fulfillment']
  end

  def order_to_high_notification
    configuration['notification']['client']['order_to_high']
  end

  def couriers_availables
    configuration['opit']['couriers'].map do |courier|
      courier[courier.keys.first]
    end
  end

  def update_courier(courier, algorithm)
    configuration['opit']['couriers'].map do |object|
      next unless object.keys.include?(courier[:acronym])

      object[courier[:acronym]].merge!(courier.as_json)
    end
    configuration['opit']['algorithm'] = algorithm['kind']
    configuration['opit']['algorithm_days'] = algorithm['days']
    update_columns(configuration: configuration)
  end

  def update_algorithm(algorithm)
    configuration['opit']['algorithm'] = algorithm['kind']
    configuration['opit']['algorithm_days'] = algorithm['days']
    update_columns(configuration: configuration)
  end

  def courier(acronym)
    configuration['opit']['couriers'].find do |object|
      next unless object.keys.include?(acronym)

      object[acronym]
    end
  end

  def algorithm
    { days: configuration['opit']['algorithm_days'], kind: configuration['opit']['algorithm'] }
  end

  def shipping_algorithm
    { algorithm_days: configuration['opit']['algorithm_days'], algorithm: configuration['opit']['algorithm'] }
  end

  def couriers_actives
    configuration['opit']['couriers'].map { |k| Courier.achronim_to_name(k.keys[0]) if k[k.keys[0]]['available'] }.compact
  end

  def printer_available
    configuration['printers']['availables'].find { |p| p['active'] }
  end

  def label_package_size
    configuration['printers']['label_package_size']
  end

  def sellers_availables
    sellers = configuration['fullit']['sellers'].select do |seller|
      (seller[seller.keys.first]['client_id'].present? && seller[seller.keys.first]['client_secret'].present?) || seller[seller.keys.first]['access_token'].present?
    end
    sellers
  end

  def active_suite_sellers(sellers = [])
    sellers.reject do |seller|
      %w[prestashop bsale dafiti opencart drupal magento_one magento_two api2cart].include?(seller.keys.first)
    end
  end

  def default_template_notification
    {
      client: {
        pickup: true,
        state: {
          in_preparation: true,
          delivered: true,
          failed: false
        },
        order_to_high: { enable: false, amount: 100_000 },
        fulfillment: { broke_stock: false,
                       security_stock: false,
                       email: '' }
      },
      buyer: {
        mail: {
          cc: '',
          state: {
            in_preparation: { active: true, cc: false },
            in_route: { active: true, cc: false },
            by_retired: { active: true, cc: false },
            delivered: { active: true, cc: false },
            failed: { active: false, cc: false }
          },
          surveys: {
            csat: { active: false, cc: false }
          }
        },
        whatsapp: {
          state: {
            in_preparation: { active: true },
            in_route: { active: true },
            by_retired: { active: true },
            delivered: { active: true },
            failed: { active: false }
          }
        }
      }
    }
  end

  def default_template_printers
    {
      availables: [{ active: true, format: 'zpl', provider: 'PRINT_NODE', sizes: '4x4', quantity: 1, name: 'zpl', img: 'https://printer-labels.s3-us-west-2.amazonaws.com/ST/2018/4/2/pack_296886__02_04_2018__912023401.pdf' }],
      available_to_add_providers: false,
      kind_of_print: 'download',
      label_package_size: '4x4',
      formats: [{ format: 5197,  provider: 'WEB_BROWSER', sizes: '4x1.5',  quantity: 12, name: 'avery', img: '/assets/avery/5197.jpg', display: '6x2' },
                { format: 5162,  provider: 'WEB_BROWSER', sizes: '4x1.33', quantity: 14, name: 'avery', img: '/assets/avery/5162.jpg', display: '7x2' },
                { format: 5163,  provider: 'WEB_BROWSER', sizes: '4x1.33', quantity: 10, name: 'avery', img: '/assets/avery/5163.jpg', display: '5x2' },
                { format: 5164,  provider: 'WEB_BROWSER', sizes: '4x3.33', quantity: 6,  name: 'avery', img: '/assets/avery/5164.jpg', display: '3x2' },
                { format: 5168,  provider: 'WEB_BROWSER', sizes: '3.5x5',  quantity: 4,  name: 'avery', img: '/assets/avery/5168.jpg', display: '2x2' },
                { format: 6874,  provider: 'WEB_BROWSER', sizes: '3.75x3', quantity: 6,  name: 'avery', img: '/assets/avery/6874.png', display: '3x2' },
                { format: 6873,  provider: 'WEB_BROWSER', sizes: '3.75x2', quantity: 8,  name: 'avery', img: '/assets/avery/6873.png', display: '4x2' },
                { format: 5292,  provider: 'WEB_BROWSER', sizes: '4x6',    quantity: 1,  name: 'avery', img: '/assets/avery/5292.png', display: '1x1' },
                { format: 'zpl', provider: 'PRINT_NODE',  sizes: '4x4',    quantity: 1,  name: 'zpl',   img: 'https://printer-labels.s3-us-west-2.amazonaws.com/ST/2018/4/2/pack_296886__02_04_2018__912023401.pdf' },
                { format: 'epl', provider: 'PRINT_NODE',  sizes: '4x4',    quantity: 1,  name: 'epl',   img: 'https://printer-labels.s3-us-west-2.amazonaws.com/ST/2018/4/2/pack_296886__02_04_2018__912023401.pdf' }]
    }
  end

  def default_template_analytics
    {
      available: true,
      active_mailer: false,
      emails: [],
      analytics_period: '',
      days: '',
      send_period: ''
    }
  end

  def pick_and_pack_template
    { sandbox: false,
      webhook: {
        package: {
          url: '',
          options: {
            sign_body: {
              required: false,
              token: ''
            },
            authorization: {
              required: false,
              kind: 'Basic',
              token: ''
            }
          }
        },
        pickup: {
          url: '',
          options: {
            sign_body: {
              required: false,
              token: ''
            },
            authorization: {
              required: false,
              kind: 'Basic',
              token: ''
            }
          }
        }
      }
    }
  end

  def template_sellers
    %w[dafiti bootic bsale shopify woocommerce prestashop opencart jumpseller vtex drupal magento_one magento_two].map do |seller|
      { seller => Rails.configuration.integration }
    end
  end

  def template_couriers
    country = company&.get_country
    case country&.country_code
    when 'mx' [{ muvsmart_mx: { available: false }.merge(base_tcc('muvsmart_mx', 'mx')) }]
    else
      [{ cxp: { is_cost: true,
                is_price: true,
                available: true,
              }.merge(base_tcc('chilexpress')) },
       { stk: { is_cost: false,
                is_price: true,
                available: true }.merge(base_tcc('starken')) },
       { cc: { is_cost: true,
               is_price: false,
               available: false }.merge(base_tcc('correoschile')) },
       { dhl: { available: false }.merge(base_tcc('dhl')) },
       { muvsmart: { available: false }.merge(base_tcc('muvsmart')) },
       { chileparcels: { available: true }.merge(base_tcc('chileparcels')) },
       { motopartner: { available: true }.merge(base_tcc('motopartner')) },
       { bluexpress: { available: false }.merge(base_tcc('bluexpress')) },
       { shippify: { available: false }.merge(base_tcc('shippify')) }]
    end
  end

  def template_automatizations
    { insurance: { active: false, amount: 0 }}
  end

  def opit_template
    {
      couriers: template_couriers,
      is_new_courier_price_enabled: true,
      algorithm_days: '',
      algorithm: '1',
      is_backoffice_couriers_enabled: false
    }
  end

  # country = cl or mx
  def current_template_couriers(courier, country = DEFAULT_COUNTRY)
    return {} if courier.blank?

    template =
      case courier
      when *Courier::AVAILABLE_COURIERS.keys then { available: true }
      else { available: false }
      end

    template.merge(base_tcc(courier, country))
  end

  def base_tcc(courier, country = DEFAULT_COUNTRY)
    data = Rails.configuration.send(courier)
    base = country_base_tcc(country).with_indifferent_access
    base.merge!(services: Courier.services_by_courier(courier, company_id))
    base.merge(data.with_indifferent_access)
  rescue StandardError => _e
    Rails.logger.info('base_tcc is not found'.red)
    {}
  end

  # all values and settings for countries will be in config/countries.yml
  # and were loaded with config_for
  # you can read more about it here -> https://guides.rubyonrails.org/configuring.html#custom-configuration
  def countries_yml
    @countries_yml ||= Rails.configuration.countries
  end

  def country_base_tcc(country = DEFAULT_COUNTRY)
    country ||= DEFAULT_COUNTRY
    countries_yml.dig('base_tcc', country)
  rescue StandardError => _e
    Rails.logger.info('country_base_tcc is not found'.red)
    {}
  end

  def set_account_printer
    company.current_account.update_columns(id_printer: configuration['printers']['availables'][0]['id_printer']) if configuration['printers']['availables'][0].keys.include?('id_printer')
  end

  def create_or_update_checkout
    fullit = Setting.find_by(service_id: 2, company_id: company.id)
    template_checkout = { checkout: { show_days: true, custom_delivery_promise: { active: false, type: 1, custom_message: 'Despacho a domicilio', min_days_plus: 0, max_days_plus: 0 } } }
    fullit.configuration['fullit']['sellers'].map do |seller|
      if seller[seller.keys[0]]['checkout'].nil?
        seller[seller.keys[0]].merge!(template_checkout)
      elsif seller[seller.keys[0]]['checkout']['custom_delivery_promise'].nil?
        seller[seller.keys[0]]['checkout'].merge!(template_checkout[:checkout][:custom_delivery_promise])
      elsif seller[seller.keys[0]]['checkout']['show_days'].nil?
        seller[seller.keys[0]]['checkout'].merge!(template_checkout[:checkout][:show_days])
      end
    end
    fullit.update_columns(configuration: fullit.configuration)
  end

  def print_labels(current_account, download, packages = [])
    available = printer_available
    case available['format']
    when 'zpl'
      if printer_way == 'download'
        LabelJob.perform_now(packages, company, current_account, download)
      else
        PrinterJob.perform_now(packages, available['id_printer'])
      end
    else
      Opit.generate_avery(packages, available, download, 'v2')
    end
  end

  def pickup_alert
    return unless service_id == 6

    configuration['notification']['client']['pickup']
  end

  def shipment_webhook
    return if service_id != 3

    configuration['pp']['webhook']['package']
  end

  def sku_webhook
    return if service_id != 4

    configuration['fulfillment']['webhook']['sku']
  end
end
