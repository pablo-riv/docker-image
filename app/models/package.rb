class Package < ApplicationRecord
  include SpreadsheetArchitect
  include Apiable
  include Filterable
  include Downloable

  COURIERS = [['Chilexpress', 'chilexpress'], ['Starken', 'starken'], ['CorreosChile', 'correoschile'], ['DHL', 'dhl'], ['MuvSmart', 'muvsmart'], ['Moto Partner', 'motopartner'], ['Glovo', 'glovo'], ['Chile Parcels', 'chileparcels'], ['Bluexpress', 'bluexpress'], ['Shippify', 'shippify']].freeze
  CLOSEST_LIMIT_HOUR = Time.now.utc.change(hour: 16, min: 0o4, sec: 59).strftime('%H%M%S') # 14:05:59 Chile
  LIMIT_HOUR = Time.now.utc.change(hour: 15, min: 0o4, sec: 59).strftime('%H%M%S') # 13:05:59 Chile
  TIMEZONE_OFFSET = Rails.configuration.timezone_offset

  ## CALLBACKS
  after_create :updating_courier_for_client
  after_create :set_apply_courier_discount
  after_commit :active_insurance, on: %i[create update]
  after_create :set_shipit_code
  after_commit :set_price, unless: %i[from_backup same_day_delivery? without_courier?]
  after_commit :publish_reindex
  after_update :update_seller, if: [:seller_package?]
  after_create :set_size, unless: %i[warehouse_integration?]
  after_create :set_operation_times
  after_create :set_tcc
  after_save :request_prediction_delivery_date, unless: %i[same_day_delivery? without_courier?]
  after_save :management_transition

  ## RELATIONS
  has_one :address
  has_one :commune, through: :address
  has_one :check, dependent: :destroy
  has_many :alerts
  has_many :whatsapps
  belongs_to :branch_office
  has_one :company, through: :branch_office
  has_one :accomplishment, dependent: :destroy
  has_paper_trail ignore: [:updated_at, :purchase, :fulfillment_files], meta: { editor_type: 'account' }
  has_many :supports
  has_many :incidences
  has_one :order
  has_one :insurance
  has_one :packages_pickups
  has_and_belongs_to_many :pickups, join_table: :packages_pickups, foreign_key: :package_id
  has_one :prediction
  has_many :shipping_managements
  has_one :package_packing
  has_one :origin_package, dependent: :destroy
  has_one :destination_package, dependent: :destroy
  has_one :return_package, dependent: :destroy

  attr_accessor :sku_select, :from_backup, :sent

  accepts_nested_attributes_for :commune
  accepts_nested_attributes_for :branch_office
  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :insurance

  default_scope { where(is_archive: false) }

  # enum status:    { in_preparation: 0, in_route: 1, delivered: 2, failed: 3, by_retired: 4, other: 5, pending: 6, to_marketplace: 7, indemnify: 8, ready_to_dispatch: 9, dispatched: 10, at_shipit: 11, returned: 12, created: 13 }
  enum status: {
    in_preparation: 0,
    created: 13,
    requested: 14,
    retired_by: 15,
    ready_to_dispatch: 9, # checkin
    dispatched: 10, # checkout
    received_for_courier: 17,
    in_route: 1,
    delivered: 2,
    failed: 3,
    failed_with_observations: 18,
    almost_failed: 19,
    by_retired: 4,
    other: 5,
    pending: 6,
    to_marketplace: 7,
    indemnify: 8,
    at_shipit: 11,
    returned: 12,
    fulfillment: 20,
    returned_in_route: 21,
    crossdock: 22
  }
  enum platform:  { form: 0, sheet: 1, api: 2, integration: 3, massive_form: 4, multi_pack: 5, from_return: 6, warehouse_integration: 7, suite: 8 }
  enum kind:      { shipit: 0, shopify: 1, prestashop: 2, woocommerce: 3, bsale: 4, jumpseller: 5, bootic: 6, opencart: 7, magento: 8 }, _prefix: :kind
  enum service:   { pick_and_pack: 0, fulfillment: 1, labelling: 2, inverse_logistic: 3 }, _prefix: :service

  delegate :in, :out, to: :check, allow_nil: true
  delegate :in_created_at, :out_created_at, to: :check, allow_nil: true, prefix: 'check'
  delegate :process, to: :accomplishment, prefix: 'accomplishment'
  delegate :client_preparation_accomplishment, to: :accomplishment, allow_nil: true
  delegate :hero_pickup_accomplishment, to: :accomplishment, allow_nil: true
  delegate :first_mile_accomplishment, to: :accomplishment, allow_nil: true
  delegate :delivery_accomplishment, to: :accomplishment, allow_nil: true
  delegate :total_accomplishment, to: :accomplishment, allow_nil: true
  delegate :default_address, to: :branch_office, allow_nil: true, prefix: 'branch_office'
  delegate :company_platform_version, to: :branch_office, allow_nil: true
  delegate :company_current_subscription, to: :branch_office, allow_nil: true
  delegate :company_apply_discount, to: :branch_office, allow_nil: true
  delegate :company_name, to: :branch_office, allow_nil: true
  delegate :commune_id, to: :address, allow_nil: true, prefix: 'address'

  # VALIDATIONS
  validates_associated :address, :commune, :branch_office
  validates_presence_of :full_name, :reference, :items_count, :shipping_type, :destiny, :packing, :branch_office_id
  validates_length_of :reference, maximum: 15
  validates :width,  numericality: { greater_than_or_equal_to: 1 }
  validates :height, numericality: { greater_than_or_equal_to: 1 }
  validates :length, numericality: { greater_than_or_equal_to: 1 }
  validates :weight, numericality: { greater_than_or_equal_to: 0.01 }

  def self.by_year(year = Date.current.year)
    where('EXTRACT(YEAR from packages.created_at)= ?', year)
  end

  def self.by_date(year = Date.current.year, month)
    where('EXTRACT(YEAR from packages.created_at)= ? AND EXTRACT(MONTH from packages.created_at)= ?', year, month)
  end

  def self.by_billing_date(year = Date.current.year, month)
    where('EXTRACT(YEAR from packages.billing_date)= ? AND EXTRACT(MONTH from packages.billing_date)= ?', year, month)
  end

  def self.calculate_days(reverse: false, current: false, datetime: DateTime.current, service: 'pp', model: DistributionCenter.default)
    CuttingHours::Generator.new(reverse: reverse,
                                current: current,
                                datetime: datetime,
                                service: service,
                                model: model).calculate_days
  end

  def self.by_day(day = Date.current.day, month = Date.current.month, year = Date.current.year, service = 'pp')
    date = Date.new(year, month, day.try(:to_i))
    from_date = (date - calculate_days(reverse: true, current: true, datetime: date, service: service))
    to_date = date
    by_operation_hour(from_date, to_date)
  end

  def self.by_specific_day(day = Date.current.day)
    where('EXTRACT(DAY from packages.created_at)= ?', day)
  end

  def self.returned
    where(is_returned: true)
  end

  def self.no_returned
    where(is_returned: false)
  end

  def self.paid_by_shipit
    where(is_paid_shipit: true)
  end

  def self.printer_ticket_today_payable
    today_packages_with_exception.payable.is_not_printed.without_tracking.order_ticket
  end

  def self.printer_ticket_today
    today_packages_with_exception.not_payable.is_not_printed.without_tracking.order_ticket
  end

  def self.latest_days(day_number = 30)
    where('packages.created_at > ?', day_number.days.ago)
  end

  def self.latest_30
    (Date.current - 30.day).strftime('%d/%m/%Y')
  end

  def self.today
    today_packages_with_exception
  end

  def self.from_billing_day(year = Date.current.year, month, day)
    where('EXTRACT(YEAR from packages.billing_date)= ? AND EXTRACT(MONTH from packages.billing_date)= ? AND EXTRACT(DAY from packages.billing_date)= ? ', year, month, day)
  end

  def self.allowed_attributes
    [:branch_office, :pickup_id, :full_name, :email, :cellphone, :length, :width, :height, :weight, :shipping_type, :approx_size, :volume_price, :sent, :order_id,
     :reference, :is_payable, :is_fragile, :is_wrapper_paper, :is_reachable, :is_printed, :is_paid_shipit, :is_returned, :is_available, :is_archive,
     :is_exception, :is_mail_to_receiver, :courier_for_entity, :courier_type, :courier_for_client, :courier_selected, :comments, :reason, :serial_number, :items_count,
     :product_type, :tracking_number, :shipping_price, :material_extra, :total_price, :shipit_code, :shipping_cost, :trello_item, :mongo_order_seller, :seller_order_id,
     :parent_ot, :has_ot, :box_type, :packing, :sell_type, :sku_supplier, :supplier_name, :craftman_state, :voucher_price, :pickup_distance, :courier_branch_office_id, :kind_of_order,
     :platform, :destiny, :without_courier, :is_sandbox, :algorithm, :algorithm_days, :with_purchase_insurance, :spreadsheet_versions, :spreadsheet_versions_destinations, :front_office,
     address_attributes: [:commune_id, :complement, :number, :street, :coords],
     inventory_activity: [:description, inventory_activity_orders_attributes: [:sku_id, :amount, :warehouse_id, :sku, :quantity, :model]],
     purchase: [:detail, :amount, :ticket_number, :extra_insurance], insurance_attributes: [:ticket_amount, :ticket_number, :extra, :detail]]
  end

  def self.returned_attributes
    [:branch_office_id, :pickup_id, :full_name, :email, :cellphone, :length, :width, :height, :weight, :shipping_type, :approx_size, :volume_price, :without_courier, :order_id,
     :reference, :is_payable, :is_fragile, :is_wrapper_paper, :is_reachable, :is_printed, :is_paid_shipit, :is_returned, :is_available, :is_archive,
     :platform, :is_sandbox, :algorithm, :algorithm_days, :courier_branch_office_id, :courier_selected,
     :is_exception, :is_mail_to_receiver, :courier_for_entity, :courier_type, :courier_for_client, :comments, :reason, :serial_number, :items_count,
     :product_type, :tracking_number, :shipping_price, :material_extra, :total_price, :shipit_code, :shipping_cost, :trello_item, :position,
     :parent_ot, :has_ot, :box_type, :packing, :sell_type, :sku_supplier, :supplier_name, :craftman_state, :voucher_price, :pickup_distance, :kind_of_order, :front_office,
     :destiny, :with_purchase_insurance, :father_reference, address_attributes: [:commune_id, :complement, :number, :street, :coords], inventory_activity: [:description, inventory_activity_orders_attributes: [:sku_id, :amount, :warehouse_id]],
     purchase: [:detail, :amount, :ticket_number, :insurance_price, :extra_insurance]]
  end

  def self.edited_attributes
    [:status, :length, :width, :height, :weight, :box_type, :volume_price, :tracking_number, :reference, :is_exception, :is_available, :is_returned, :without_courier, :order_id,
     :items_count, :destiny, :cellphone, :email, :shipping_type, :is_payable, :full_name, :is_paid_shipit, :courier_for_client, :shipping_price,
     :material_extra, :total_price, :packing, :paid_by_shipit_reason, :is_sized, :courier_selected, :with_purchase_insurance, :father_reference,
     :rebate, :ff_order_config, :ff_order_price, :ff_unit_price, :ff_order_cost, :packing_cost, :shipit_indemnify, :shipit_indemnify_amount, :courier_indemnify,
     :courier_indemnify_amount, :waste_amount, :total_lost, :front_office,
     address_attributes: [:id, :commune_id, :complement, :number, :street], insurance_attributes: [:ticket_amount, :ticket_number, :extra, :detail]]
  end

  def self.no_paid_by_shipit
    where(is_paid_shipit: false)
  end

  def self.states(account)
    packages = account.entity.specific.packages
    {
      created: packages.latest_days.by_status(:created).size,
      in_preparation: packages.latest_days.by_status(:in_preparation).size,
      in_route: packages.latest_days.by_status(:in_route).size,
      delivered: packages.latest_days.by_status(:delivered).size,
      by_retired: packages.latest_days.by_status(:by_retired).size,
      failed: packages.latest_days.by_status(:failed).size,
      other: packages.latest_days.by_status(:other).size,
      at_shipit: packages.latest_days.by_status(:at_shipit).size,
      returned: packages.latest_days.by_status(:returned).size,
      indemnify: packages.latest_days.by_status(:indemnify).size
    }
  end

  def self.by_status(block = :in_preparation)
    block = [:in_preparation, :ready_to_dispatch, :dispatched] if block == :in_preparation
    block = [:failed, :at_shipit, :returned, :indemnify] if block == :failed
    where(status: block)
  end

  def self.all_by_pickup(pickup)
    puts pickup['id'].to_s.yellow
    where(pickup_id: pickup['id'])
  end

  def self.today_packages_with_exception(timelapse = 'today')
    from_date, to_date =
      case timelapse
      when 'today' then [Date.current, Date.current]
      when 'tomorrow' then [Date.current + self.calculate_days, Date.current + self.calculate_days]
      when 'yesterday' then [Date.current - self.calculate_days(reverse: true), Date.current - self.calculate_days(reverse: true)]
      else
        [Date.current, Date.current]
      end
    dump_between_dates(from: from_date, to: to_date)
  end

  def self.labels_operation(tomorrow = false)
    date = operation_hour(tomorrow)
    by_operation_hour(date[:from], date[:to])
  end

  def self.label_select
    select("UPPER(CONCAT(addresses.street, ' ', addresses.number, ', ', communes.name, ', ', regions.name)) AS full_address, packages.id, packages.mongo_order_seller, packages.url_pack, packages.destiny, packages.reference, packages.full_name, communes.name AS commune_name, LOWER(packages.courier_for_client) AS courier, packages.tracking_number, packages.created_at, packages.label_printed, packages.printed_date, packages.pack_pdf")
  end

  def self.label_export
    select("packages.id AS id,"\
           "packages.reference AS reference,"\
           "UPPER(packages.full_name) AS full_name,"\
           "packages.email AS email,"\
           "packages.branch_office_id AS branch_office_id,"\
           "UPPER(packages.courier_for_client) AS courier,"\
           "UPPER(communes.name) AS commune_name,"\
           "packages.pack_pdf AS pack_pdf,"\
           "packages.url_pack AS url_pack,"\
           "packages.shipit_ticket_url AS shipit_ticket_url,"\
           "UPPER(CONCAT(addresses.street, ' ', addresses.number, ', ', communes.name, ', ', regions.name)) AS full_address")
  end

  def self.operation_hour(tomorrow = false)
    from_date = tomorrow ? DateTime.current.change(hour: 14, min: 4, sec: 59, offset: TIMEZONE_OFFSET) : (DateTime.current - calculate_days(reverse: true)).change(hour: 14, min: 4, sec: 59, offset: TIMEZONE_OFFSET)
    to_date = tomorrow ? (DateTime.current + calculate_days).change(hour: 14, min: 4, sec: 59, offset: TIMEZONE_OFFSET) : DateTime.current.change(hour: 14, min: 4, sec: 59, offset: TIMEZONE_OFFSET)

    { from: from_date, to: to_date }
  end

  def self.utc_offset_to_eval
    utc_offset = (Time.current.utc_offset / 3600)
    to_eval = "#{utc_offset >= 0 ? '+' : '-'} interval '#{utc_offset >= 0 ? utc_offset : utc_offset.to_s.gsub('-', '')} hours'"
  end

  def self.by_operation_hour(from_date, to_date)
    dump_between_dates(from: from_date, to: to_date)
  end

  def self.filter_couriers_availables(couriers_availables, couriers)
    couriers_availables.select { |key, value| couriers.include?(key) && value.present? }
  end

  def self.extract_insurance(package)
    raise unless package.insurance.present?

    package.insurance.attributes
  rescue => e
    { ticket_number: '', ticket_amount: 0, detail: '', extra: false }
  end

  def self.validate_destinies_by_shipment(packages, company, courier_availables)
    packages.map do |package|
      data = HashWithIndifferentAccess.new(package.serialize_data!)
      data['branch_office']['company'] = company.attributes
      couriers_availables_by_coverage =
        if company.backoffice_couriers_enabled?
          Coverages::Courier.new({ account: company.current_account }).if company.backoffice_couriers_enabled?(1, 308, package.commune.id)[:to]
        else
          data['address']['commune']['couriers_availables']
        end
      couriers = filter_couriers_availables(couriers_availables_by_coverage, courier_availables)
      availables_to =
        if data['courier_selected'] && courier_availables.include?(package.courier_for_client)
          couriers.select { |ca| package.courier_for_client.downcase == ca[package.courier_for_client] }
        elsif package.courier_for_client.present? && courier_availables.exclude?(package.courier_for_client.try(:downcase)) && package.courier_for_client.try(:downcase) != 'fulfillment delivery'
          data['courier_for_client'] = nil
          data['courier_selected'] = false
          package.update_columns(courier_for_client: nil, courier_selected: false)

          NotificationMailer.generic("#{I18n.t('email.generic.errors.package_courier_selected_error.title')} #{package.id}", I18n.t('email.generic.errors.package_courier_selected_error.message'), company).deliver
          couriers
        else
          couriers
        end

      data['address']['commune']['couriers_availables'] = availables_to
      data['insurance'] = extract_insurance(package)
      data['uf'] = Indicator.last_uf_value
      data['origin'] = package.branch_office.company.default_origin
      data['return'] = package.branch_office.company.default_origin('Return')
      data['origin_package'] = package.origin_package&.serializable_hash(methods: [:full_address, :commune_name])
      data['return_package'] = package.return_package&.serializable_hash(methods: [:full_address, :commune_name])
      data['destination_package'] = package.destination_package&.serializable_hash(methods: [:full_address, :commune_name])
      data
    end
  end

  def self.generate_template_for(service_id, packages = [], object = {})
    return false if packages.empty? || object.nil? || (service_id.nil? || service_id.blank?)

    company =
      case object.class.name
      when 'Account' then object.current_company
      when 'Company' then object
      when 'BranchOffice' then object.company
      end
    branch_office = packages.first.company_platform_version == 2 ? packages.first.branch_office : company.default_branch_office
    setting = Setting.find_by(service_id: 1, company_id: company.id)
    json_template = { packages: validate_destinies_by_shipment(packages, company, company.couriers_availables),
                      account: company.current_account,
                      setting: setting,
                      hero: branch_office.hero&.attributes,
                      location: branch_office.location.attributes,
                      address: branch_office.default_address&.serialize_data!, # CHANGE TO DEFAULT ORIGIN ADDRESS TO SUITE CUSTOMERS
                      return_address: branch_office.company_default_return_address&.serialize_data!, # CHANGE TO DEFAULT RETURN ADDRESS TO SUITE CUSTOMERS
                      company: company.attributes,
                      is_marketplace: company.branch_offices.count > 1,
                      opit: setting.attributes,
                      couriers_setting: setting.configuration['opit']['couriers'],
                      type: service_id == 4 ? 1 : nil }
    NotifyMailer.package_without_hero(json_template, branch_office).deliver unless json_template[:hero].present? || json_template[:location].present?
    json_template
  rescue => e
    Slack::Ti.new({}, {}).alert(nil, "Error al configurar template de package #{packages.first.id}\n \n COMPANY: #{company.id}-#{company.name}\nError Message: #{e.message}\nBacktrace: #{e.backtrace[0]}")
  end

  def self.endpoint_filters(packages, params)
    packages = packages.by_year(params[:year]) unless params[:year].blank?
    packages = packages.by_date(params[:year],params[:month]) unless params[:month].blank?
    packages = packages.by_specific_day(params[:day]) unless params[:day].blank?
    packages = packages.returned unless params[:returned].blank?
    packages = packages.no_returned unless params[:not_returned].blank?
    packages = packages.paid_by_shipit unless params[:paid_by_shipit].blank?
    packages = packages.no_paid_by_shipit unless params[:not_paid_by_shipit].blank?
    packages = packages.today unless params[:today].blank?
    packages = packages.order("#{params[:order]} #{params[:direction]}") unless params[:today].blank? && params[:direction].blank?
    packages
  end

  def self.from_courier(courier_for_client)
    where('LOWER(courier_for_client) = ?', courier_for_client)
  end

  def self.from_chilexpress
    where("LOWER(courier_for_client) = 'chilexpress'")
  end

  def self.from_starken
    where("LOWER(courier_for_client) = 'starken'")
  end

  def self.from_dhl
    where("LOWER(courier_for_client) = 'dhl'")
  end

  def self.from_muvsmart
    where("LOWER(courier_for_client) = 'muvsmart'")
  end

  def self.from_chileparcels
    where("LOWER(courier_for_client) = 'chileparcels'")
  end

  def self.from_motopartner
    where("LOWER(courier_for_client) = 'motopartner'")
  end

  def self.from_bluexpress
    where("LOWER(courier_for_client) = 'bluexpress'")
  end

  def self.from_shippify
    where("LOWER(courier_for_client) = 'shippify'")
  end

  def self.without_courier
    where(courier_for_client: ['', nil]).where.not(without_courier: true)
  end

  def self.with_courier
    where.not(courier_for_client: ['', nil, 'Fulfillment Delivery'])
  end

  def self.order_ticket
    joins(branch_office: :location).joins(branch_office: :entity).order('packages.is_returned DESC, locations.hero_id DESC, entities.name DESC, packages.reference, packages.courier_for_entity')
  end

  def self.without_tracking
    where(tracking_number: [nil, '']).where.not(without_courier: true)
  end

  def self.with_tracking
    where.not(tracking_number: [nil, ''], url_pack: [nil, ''])
  end

  def self.payable
    where(is_payable: true)
  end

  def self.is_not_payable
    where(is_payable: false)
  end

  def self.is_not_printed
    where(is_printed: false, is_courier_printed: false)
  end

  def self.without_checks
    left_outer_joins(:check).where('checks.id IS NULL')
  end

  def self.not_sandbox
    where(is_sandbox: false)
  end

  def self.not_test
    where.not("LOWER(reference) like '%test-%'")
  end

  def self.in_preparation
    where(status: :in_preparation)
  end

  def self.created
    where(status: :created)
  end

  def self.between_dates(from, to)
    where(created_at: (from.to_date.at_beginning_of_day..to.to_date.at_end_of_day))
  end

   # OPTIMIZE: This block must be refactor since those filters can be wrong
  def self.to_get_tracking
    packages = without_tracking.select { |p| !p.courier_for_client.blank? }
    packages = packages.select do |p|
      case p.courier_for_client.try(:downcase)
      when 'chilexpress' then p if !(p.is_payable == true && p.courier_for_client.try(:downcase) == 'chilexpress' && p.destiny != "Domicilio")
      else
        p
      end
    end
  end

  def self.complete_date(year, month, day)
    date = DateTime.new(year, month, day)
    from_date = (date - calculate_days(reverse: true, current: true, datetime: date))
    to_date = date
    includes(:branch_office, address: :commune).where(without_courier: false).by_operation_hour(from_date, to_date).where(without_courier: false)
  end

  def self.by_warehouse(id = 2)
    where("inventory_activity -> 'inventory_activity_orders_attributes' -> 0 ->> 'warehouse_id' = '?'", id)
  end

  def self.from_ff
    where("inventory_activity ->> 'inventory_activity_orders_attributes' IS NOT NULL")
  end

  def self.from_pp
    where("inventory_activity ->> 'inventory_activity_orders_attributes' IS NULL")
  end

  def self.sum_fulfillment_charges(object)
    return 0 unless object.present?

    data =
      if object[:type].include?('day')
        where(branch_office_id: object[:ids]).from_billing_day(object[:from].year, object[:from].month, object[:from].day)
      else
        where(branch_office_id: object[:ids]).by_billing_date(object[:from], object[:to])
      end
    data = data.no_paid_by_shipit.not_sandbox.not_test
    objs = data.map do |package|
      {
        shipping_price: package.shipping_price || 0,
        material_extra: package.material_extra || 0,
        total_is_payable: package.total_is_payable || 0
      }
    end
    shipments = objs.sum { |obj| obj[:shipping_price] || 0 }
    material_extra = objs.sum { |obj| obj[:material_extra] || 0 }
    total_is_payable = objs.sum { |obj| obj[:total_is_payable] || 0 }
    total = shipments.to_f + material_extra.to_f + total_is_payable.to_f
    { shipments: shipments.round, material_extra: material_extra.round, total_is_payable: total_is_payable.round, total_price: total.round }
  end

  def self.download(from, to, status, courier)
    includes(:commune, :address).where(created_at: (from.to_date.at_beginning_of_day..to.to_date.at_end_of_day), status: status_filter(status), courier_for_client: courier).order(created_at: :desc)
  end

  def self.status_filter(status)
    case status
    when 'created' then 'created'
    when 'in_preparation' then ['in_preparation', 'ready_to_dispatch', 'dispatched', 'fulfillment']
    when 'in_route' then ['in_route']
    when 'delivered' then ['delivered']
    when 'by_retired' then ['by_retired']
    when 'other' then ['other']
    when 'failed' then ['failed', 'at_shipit', 'returned', 'indemnify']
    else
      statuses.keys
    end
  end

  def self.generate_xlxs_file(packages, from, to, company_name, with_series = false)
    File.open("#{Rails.root}/public/#{company_name.gsub('/', '_')} Envíos #{from} - #{to}.xlsx", 'w+b') do |f|
      if with_series
        # f.write(packages.first.spreadsheet_headers(true))
        data = []
        packages.each do |package|
          if package.service == 'fulfillment'
            p_series = package.ff_series
            if p_series.size.positive?
              if p_series.is_a?(Array)
                p_series.each do |ff_serie|
                  data << package.ff_spreadsheet_columns(ff_serie)
                end
              else
                data << package.spreadsheet_values
              end
            else
              data << package.spreadsheet_values
            end
          else
            data << package.spreadsheet_values
          end
        end
        f.write(SpreadsheetArchitect.to_xlsx(headers: packages.first.spreadsheet_headers(with_series), data: data))
      else
        f.write(packages.to_xlsx)
      end
    end
  end

  def self.no_multipack
    where(father_reference: [nil, ''])
  end

  def self.select_tracking_data(number)
    joins(:address, address: :commune).where(tracking_number: number).
      select('packages.id, packages.reference, packages.courier_for_client, communes.name AS commune_name, packages.delivery_time, packages.shipit_code, packages.branch_office_id, packages.tracking_number, packages.status, packages.sub_status').last
  end

  def self.accomplishment_select
    select("checks.in ->> 'created_at' AS in_created_at, checks.in ->> 'branch_office_id' AS in_branch_office_id,"\
           "checks.out ->> 'created_at' AS out_created_at,"\
           'packages.id, packages.created_at, packages.mongo_order_id, packages.status, packages.sub_status,'\
           'packages.courier_status_updated_at, packages.delayed, packages.delivery_time, packages.tracking_number')
  end

  def self.valid_for_manifest(id)
    joins(:packages_pickups)
      .where(packages_pickups: { deleted_at: nil, pickup_id: id })
      .includes(address: :commune).order(:id)
  end

  def restore_ff_activity
    request = FulfillmentService.cancel_packages([id])
    raise 'No se pudo restablecer el stock' if request.include?('error')
  end

  def fulfillment?
    service.include?('FF')
  end

  def pick_and_pack?
    service.include?('PP')
  end

  def send_inventory
    company = branch_office.company
    ff_packages = Package.valid_ff_format(Package.generate_template_for(4, [self], company.current_account)[:packages])
    response = FulfillmentService.create_package({ packages: ff_packages }, company.id)
    Rails.logger.info "FF response #{response}".green.swap
    true
  rescue => e
    Rails.logger.info "FF response #{e.message}\n#{e.backtrace[0]}".red.swap
    RetryFfPackagesWorker.perform_in(15.minutes, packages: ff_packages, current_account: company.current_account, company_id: company.id)
    false
  end

  def send_pickup
    company = branch_office.company
    Publisher.publish('mass', Package.generate_template_for(3, [self], company.current_account))
  end

  def publish_reindex
    Publisher.publish('reindex_shipment', { id: self.id })
  end

  def self.dump_between_dates(interval)
    interval[:from] = interval[:from].to_date
    interval[:to] = interval[:to].to_date
    date_ranges = {
      from: (interval[:from] == interval[:to] ? interval[:from] - calculate_days(reverse: true, current: false, datetime: interval[:from]) : interval[:from]).strftime('%d/%m/%Y'),
      to: interval[:to].strftime('%d/%m/%Y'),
      operation_from: interval[:from].strftime('%d/%m/%Y'),
      operation_to: interval[:to].strftime('%d/%m/%Y')
    }

    includes(
      {
        branch_office: :company
      },
      :alerts,
      :address,
      :commune,
      :check
    ).where(
      short_query_str,
      date_ranges[:from],
      date_ranges[:to],
      date_ranges[:operation_from],
      date_ranges[:operation_to]
    ).order(created_at: :desc)
  end

  def self.dump_between_dates_and_status(interval, status = 'in_preparation')
    dump_between_dates(interval).where(status: status)
  end

  def self.dump_between_dates_analytics(interval)
    between_dates(interval[:from], interval[:to]).includes(
      {
        branch_office: :company
      },
      :alerts,
      :address,
      :commune
    )
  end

  def self.limit_hour?(package)
    return true unless package.created_at.workday?

    limit_hour_by_service = package.operation_cutting_hour.blank? ? CuttingHours::Generator.new(model: package.branch_office, service: package.service).calculate_cutting_hour : package.operation_cutting_hour
    (package.created_at).strftime('%H:%M') >= limit_hour_by_service
    # 12:33 (16:33) >= 13:00 (17:00)
  rescue ArgumentError => _e
    true
  end

  def self.calendar_packages(params)
    interval = { from: (params[:start_date].try(:to_date) || Date.current).beginning_of_month, to: (params[:start_date].try(:to_date) || Date.current).end_of_month }
    interval[:from] = interval[:from].strftime('%d/%m/%Y')
    interval[:to] = interval[:to].strftime('%d/%m/%Y')
    filterable_params = params.slice('from_courier', 'from_service')
    base = Package.not_sandbox.not_test.dump_between_dates(interval).where.not(branch_office_id: 1)
    base = filterable_params.blank? ? base : Package.filterable_with_base(base, filterable_params)
    base.select { |p| !p.statuses_condition }
  end

  def self.build_return(company, data, shipment)
    returned_shipment = new(data)
    returned_shipment.reference = "D#{returned_shipment.reference[0..13]}"
    raise 'Envio duplicado' if company.packages.where(reference: returned_shipment.reference).present?

    returned_shipment.position = shipment.position
    returned_shipment.father_id = shipment.father_id
    returned_shipment.status = :in_preparation
    returned_shipment.sub_status = ''
    returned_shipment.courier_status = ''
    returned_shipment.courier_status_updated_at = nil
    returned_shipment.shipit_status_updated_at = nil
    returned_shipment.tracking_number = ''
    returned_shipment.shipping_cost = 0
    returned_shipment.material_extra = 0
    returned_shipment.courier_selected = false
    returned_shipment.created_at = nil
    returned_shipment.updated_at = nil
    returned_shipment.courier_url = nil
    returned_shipment.url_pack = nil
    returned_shipment.pack_pdf = nil
    returned_shipment.delayed = false
    returned_shipment.return_created_at = nil
    returned_shipment.automatic_retry_date = nil
    returned_shipment.trello_item = ''
    returned_shipment.is_sized = false
    returned_shipment.pack_date_time = nil
    returned_shipment.sized_date_time = nil
    returned_shipment
  end

  def notifications_mails
    Notification.send({ data: self, type: :failed }) if failed?
  end

  def updating_courier_for_client
    update_columns(courier_selected: courier_activated?)
  end

  def limit_hour
    # distance = self.branch_office.location.distance
    distance = 0
    is_tomorrow =
      if distance.zero?
        Time.now.utc.strftime('%H%M%S') < CLOSEST_LIMIT_HOUR ? false : true
      else
        Time.now.utc.strftime('%H%M%S') < LIMIT_HOUR ? false : true
      end
    is_tomorrow
  end

  def delivery_type
    return unless shipping_type.include?('Mismo día')
    shippify = ShippifyService.new
    delivery = DeliveryService.new(shippify.task)
    delivery_full_address = "#{address.street} #{address.number}, #{address.commune.name.downcase}, Región #{address.commune.region.name}, Chile"
    delivery_lat_long = Geocoder.coordinates(delivery_full_address)
    pickup_full_address = "#{branch_office.acting_as.address.street} #{branch_office.acting_as.address.number}, #{branch_office.acting_as.address.commune.name.downcase}, Región #{branch_office.acting_as.address.commune.region.name}, Chile"
    pickup_lat_long = Geocoder.coordinates(pickup_full_address)
    delivery[:task][:ref_id] = reference
    delivery[:task][:sender][:email] = email
    delivery[:task][:recipient] = { name: full_name, email: email, phone: cellphone }
    delivery[:task][:deliver] = { lat: delivery_lat_long.first, lng: delivery_lat_long.second, address: delivery_full_address }
    delivery[:task][:pickup] = { lat: pickup_lat_long.first, lng: pickup_lat_long.second, address: pickup_full_address }
    delivery[:task][:total_amount] = total_price
    delivery[:task][:payment_status] = is_payable ? 2 : 1
    delivery[:task][:products] = { name: reference, qty: items_count, size: delivery.approx_size(approx_size) }
    response = shippify.create_task(delivery)
    Rails.logger.info { "🚴 #{response}".yellow }
    delivery[:task].merge(response.to_options)
    delivery.save ? delivery : raise('Envío no guardado')
  rescue => e
    puts e.message.to_s.red if raise ActiveRecord::Rollback
  end

  def retry_fulfillment
    current_account = branch_office.company.accounts.first
    ff_packages = Package.generate_template_for(4, [self], current_account)
    response = FulfillmentService.create_package({ packages: ff_packages[:packages] }, current_account.current_company.id)
    Rails.logger.info "FF response #{response}"
  end

  def set_price
    courier_for_client = nil unless courier_selected?
    return 'Envio con precio automatico' if warehouse_integration?
    Publisher.publish('post_prices', Package.generate_template_for(1, [self], branch_office.company)) unless without_courier?
  end

  def set_ff_price
    object = self.to_json(include: { address: { include: :commune } })
    response = FulfillmentService.get_price(object)
    #AGREGAR CALCULO DE DATOS INTERNOS, POR PAGAR, ETC,
    self.update_columns(ff_courier_for_client: response['package_courier_for_client'],
                        ff_courier_for_entity: response['package_courier_for_entity'],
                        ff_shipping_price: response['package_price'].try(:round),
                        ff_shipping_cost: response['package_cost'].try(:round),
                        ff_delivery_time: response['package_delivery_time'],
                        ff_width: response['width'],
                        ff_height: response['height'],
                        ff_items_count: response ['amount'],
                        ff_weight: response['weight'])
  end

  def set_tracking
    Publisher.publish('post_tracking', Package.generate_template_for(1, [self], branch_office.company)) if can_generate_tracking?
  end

  def can_generate_tracking?
    !without_courier? && courier_for_client.present? && Courier.exists?(["tracking_generator LIKE '%task%' AND LOWER(name) = ?", courier_for_client.downcase])
  end

  def shipit_code!
    shipit_code = "#{branch_office.company.name[0..6]} / #{reference[0..9]}"
    update_columns(shipit_code: shipit_code)
    shipit_code
  end

  def same_day_delivery?
    sdd_couriers_symbols = Courier.available_with_same_day_delivery.pluck(:symbol)
    sdd_couriers_symbols.include?(courier_for_client.try(:downcase))
  end

  def update_seller
    if company_platform_version == 2
      UpdateSellerOrdersJob.perform_now(self)
    else
      seller = company.seller_configuration(mongo_order_seller)
      return if %w[woocommerce dafiti prestashop jumpseller].include?(seller[:name])
      return if seller[:configuration][:version] == 2 && seller[:name] == 'shopify'

      Publisher.publish('update_seller_order', shipment: seller_shipment_data,
                                               company_id: company.id,
                                               name: seller[:name],
                                               configuration: seller[:configuration])
    end
  end

  def seller_package?
    mongo_order_id.present? || seller_order_id.present?
  end

  def seller_shipment_data
    { id: id,
      reference: reference,
      tracking_number: tracking_number,
      courier_for_client: courier_for_client,
      total_price: total_price,
      seller: mongo_order_seller,
      tracking_url: courier_tracking_link,
      label: pack_pdf,
      status: status,
      seller_order_id: seller_order_id,
      address: shipment_address_by_state,
      courier_status_updated_at: courier_status_updated_at,
      shipping_price: shipping_price,
      shipping_cost: shipping_cost,
      insurance: insurance_price,
      total_is_payable: total_is_payable,
      delivery_type: estimated_delivery,
      algorithm: algorithm,
      algorithm_days: algorithm_days }
  end

  def shipment_address_by_state
    a = status == 'in_preparation' ? branch_office.default_address : address
    { street: a.street,
      number: a.number,
      complement: a.complement,
      commune: a.commune.name,
      region: a.commune.region.name }
  end

  def serialize_data!
    base = serializable_hash(include: { address: { include: { commune: { include: [:region] } },
                                                   methods: [:full] } })
    HashWithIndifferentAccess.new(base.merge!(branch_office: branch_office.attributes.merge(address: branch_office.default_address.serialize_data!)))
  end

  def serialize_address
    serializable_hash(include: :address)
  end

  def courier_url
    return 'Sin tracking' if tracking_number.blank?

    case courier_for_client.try(:downcase)
    when 'chilexpress' then "http://chilexpress.cl/Views/ChilexpressCL/Resultado-busqueda.aspx?DATA=#{tracking_number}"
    when 'starken' then "https://www.starken.cl/seguimiento?codigo=#{tracking_number}"
    when 'correoschile' then "https://www.correos.cl/SitePages/seguimiento/seguimiento.aspx?envio=#{tracking_number}"
    when 'dhl' then "http://webtrack.dhlglobalmail.com/?id=39961&trackingnumber=#{tracking_number}"
    when 'muvsmart', '99minutos' then "https://tracking.99minutos.com/search/#{tracking_number}"
    when 'chileparcels' then "https://seguimiento.shipit.cl/statuses?number=#{tracking_number}"
    when 'motopartner', 'moto_partner' then "https://www.motopartner.cl/#!/main/track?code=#{tracking_number}"
    when 'bluexpress' then "http://www.bluex.cl/nacional?documentos=#{tracking_number}"
    when 'shippify' then "https://api.shippify.co/track/#{tracking_number}"
    end
  end

  def courier_activated?
    courier_for_client.present?
  end

  def dispatch_webhook(kind_of_call: 'patch')
    webhook = Setting.pp(company.id).shipment_webhook
    return unless webhook['url'].present?

    webhook_notification = WebhookNotification.create(model_id: id,
                                                      model_sent: self.class.name.try(:capitalize),
                                                      kind_of_call: kind_of_call,
                                                      url_sent: webhook['url'],
                                                      tries_made: 0,
                                                      max_retries: 5,
                                                      success: false)

    Publisher.publish('shipment_webhook', company: company.notification_serialize_data,
                                          webhook_notification: webhook_notification.attributes,
                                          setting: webhook,
                                          data: webhook_interface)
  end

  def webhook_interface
    {
      id: id,
      reference: reference,
      full_name: full_name,
      email: email,
      items_count: items_count,
      cellphone: cellphone,
      is_payable: is_payable,
      tracking_url: tracking_url,
      packing: packing,
      shipping_type: shipping_type,
      destiny: destiny,
      courier_for_client: courier_for_client,
      tracking_number: tracking_number,
      seller_order_id: seller_order_id,
      is_returned: is_returned,
      total_is_payable: total_is_payable,
      shipping_price: shipping_price,
      material_extra: material_extra,
      total_price: total_price,
      volume_price: volume_price,
      approx_size: approx_size,
      status: status,
      sub_status: sub_status,
      courier_status: courier_status,
      courier_status_updated_at: courier_status_updated_at,
      length: length,
      width: width,
      height: height,
      weight: weight,
      delivery_time: delivery_time,
      created_at: created_at,
      updated_at: updated_at,
      courier_url: courier_url,
      old_ticket_url_courier: courier_url,
      ticket_shipit_url: shipit_ticket_url,
      ticket_url: url_pack,
      ticket_shipit_pdf_url: pack_pdf,
      link: "https://api.shipit.cl/v/packages/#{id}",
      address: {
        street: try(:address).try(:street),
        number: try(:address).try(:number),
        complement: try(:address).try(:complement),
        commune: try(:address).try(:commune).try(:name),
        commune_id: try(:address).try(:commune).try(:id),
        coords: try(:address).try(:coords)
      },
      inventory_activity: inventory_activity,
      integration_reference: integration_reference
    }
  end

  def courier_for_client?
    courier_for_client.present? && !is_payable && courier_for_client == 'chilexpress'
  end

  def set_shipit_code
    update_attributes(shipit_code: "#{branch_office.company.name[0..6]} / #{reference[0..9]}")
  end

  def set_size
    return if width >= 0.1 && height >= 0.1 && length >= 0.1 && weight >= 0.1

    size =
      case approx_size
      when 'Pequeño (10x10x10cm)'
        { length: 10, width: 10, height: 10, weight: 1 }
      when 'Mediano (30x30x30cm)'
        { length: 30, width: 30, height: 30, weight: 3 }
      when 'Grande (50x50x50cm)'
        { length: 50, width: 50, height: 50, weight: 8 }
      when 'Muy Grande (>60x60x60cm)'
        { length: 60, width: 60, height: 60, weight: 20 }
      else
        { length: 10, width: 10, height: 10, weight: 1 }
      end
    update_columns(size)
  end

  def test_package?
    reference.to_s.downcase.start_with?('test-') || is_sandbox?
  end

  def integration_reference
    return unless seller_package?

    order =
      if branch_office.company.platform_version == 2
        OrderService.where(id: mongo_order_id).first.try('seller_reference')
      else
        ApplicationRecord::Order.find_by(company_id: branch_office.company.id, reference: reference).try(:reference)
      end
    order.presence || {}
  rescue StandardError => e
    {}
  end

  def profit
    shipping_price.try(:to_i) - shipping_cost.try(:to_i) unless shipping_price.blank? || shipping_cost.blank?
  end

  def has_incomplete_sizes?
    length.blank? || width.blank? || height.blank?
  end

  def volume
    length * width * height unless has_incomplete_sizes?
  end

  def service
    inventory_activity.blank? ? 'PP' : 'FF'
  end

  def alert_price_too_high
    setting = Setting.notification(branch_office.company.id)
    configuration = setting.order_to_high_notification
    return unless configuration && configuration['enable'] && total_price.to_i > configuration['amount'].try(:to_i)
    OrderMailer.too_high(self, branch_office.company.accounts.first, configuration['amount']).deliver
  end

  def status_name(status, courier = nil)
    case status
    when 'created' then I18n.t('activerecord.attributes.package.statuses.created')
    when 'in_preparation', 'ready_to_dispatch' then I18n.t('activerecord.attributes.package.statuses.in_preparation')
    when 'in_route' then I18n.t('activerecord.attributes.package.statuses.in_route')
    when 'delivered' then I18n.t('activerecord.attributes.package.statuses.delivered')
    when 'failed', 'indemnify' then I18n.t('activerecord.attributes.package.statuses.failed')
    when 'by_retired' then I18n.t('activerecord.attributes.package.statuses.by_retired')
    when 'dispatched' then I18n.t('activerecord.attributes.package.statuses.dispatched')
    when 'at_shipit' then I18n.t('activerecord.attributes.package.statuses.at_shipit')
    when 'returned' then I18n.t('activerecord.attributes.package.statuses.returned')
    when 'other' then I18n.t('activerecord.attributes.package.statuses.other')
    when 'pending' then I18n.t('activerecord.attributes.package.statuses.pending')
    when 'to_marketplace' then I18n.t('activerecord.attributes.package.statuses.to_marketplace')
    when 'requested' then I18n.t('activerecord.attributes.package.statuses.requested')
    when 'retired_by' then I18n.t('activerecord.attributes.package.statuses.retired_by')
    when 'received_for_courier' then I18n.t('activerecord.attributes.package.statuses.received_for_courier')
    when 'failed_with_observations' then I18n.t('activerecord.attributes.package.statuses.failed_with_observations')
    when 'almost_failed' then I18n.t('activerecord.attributes.package.statuses.almost_failed')
    when 'fulfillment' then I18n.t('activerecord.attributes.package.statuses.fulfillment')
    when 'returned_in_route' then I18n.t('activerecord.attributes.package.statuses.returned_in_route')
    when 'crossdock' then I18n.t('activerecord.attributes.package.statuses.crossdock')
    else
      'Sin Estado Asignado'
    end
  end

  def courier_tracking_link
    return 'Sin tracking' if tracking_number.blank?

    "https://seguimiento.shipit.cl/statuses?number=#{tracking_number}"
  end

  def tracking_url
    return 'Sin tracking' if tracking_number.blank?

    "https://seguimiento.shipit.cl/statuses?number=#{tracking_number}"
  end

  def staff_link
    "http://staff.shipit.cl/administration/packages/#{id}"
  end

  def ff_spreadsheet_columns(ff_serie)
    temp_value = spreadsheet_values
    temp_value << ff_serie['name']
    temp_value << ff_serie['sku']['name']
    temp_value
  end

  def statuses_condition
    case status
    when 'in_preparation', 'fulfillment'
      Date.current <= 1.business_days.after(created_at.to_date)
    when 'ready_to_dispatch'
      check_in_created_at.present? && Date.current <= 1.business_days.after(check_in_created_at.to_date)
    when 'dispatched'
      check_out_created_at.present? && Date.current <= 1.business_days.after(check_out_created_at.to_date)
    when 'in_route'
      !self.delayed
    when 'failed', 'by_retired', 'pending'
      false
    else
      true
    end
  end

  def monitor_condition
    case status
    when 'in_preparation', 'fulfillment'
      Date.current <= 1.business_days.after(created_at.to_date)
    when 'ready_to_dispatch'
      in_created_at.present? && Date.current <= 1.business_days.after(in_created_at.to_date)
    when 'dispatched'
      out_created_at.present? && Date.current <= 1.business_days.after(out_created_at.to_date)
    when 'in_route'
      !self.delayed
    when 'failed', 'by_retired', 'pending'
      false
    else
      true
    end
  end

  def set_operation_times
    set_operation_cutting_hour
    set_operation_date
  end

  def start_time
    set_operation_date if operation_date.blank?
    operation_date.to_datetime + 9.hours
  end

  def set_operation_date
    days_to_add = Package.calculate_days(reverse: false, current: false, datetime: created_at.to_datetime, service: service.try(:downcase), model: branch_office)
    date = Package.limit_hour?(self) ? (created_at + days_to_add.days).to_date : created_at.to_date
    update_columns(operation_date: date)
  end

  def set_operation_cutting_hour
    cutting = CuttingHours::Generator.new(model: branch_office, service: service).calculate_cutting_hour
    return if cutting.blank?

    update_columns(operation_cutting_hour: cutting.split('-')[0])
  end

  def self.short_query_str
    "CASE
      WHEN packages.operation_date is NULL THEN
        (packages.created_at::timestamptz)
        between
        TO_TIMESTAMP(CONCAT(?, ' 17:05:00'), 'DD/MM/YYYY HH24:MI:SS')
        AND
        TO_TIMESTAMP(CONCAT(?, ' 17:05:00'), 'DD/MM/YYYY HH24:MI:SS')
        ELSE
        (packages.operation_date::timestamptz)
        between
        TO_TIMESTAMP(?, 'DD/MM/YYYY')
        AND
        TO_TIMESTAMP(?, 'DD/MM/YYYY')
      END
    "
  end

  def self.query_str
    "CASE
      WHEN packages.operation_date is NULL THEN
        CASE
          WHEN packages.operation_cutting_hour is NULL THEN
            (packages.created_at::timestamptz)
            between
            TO_TIMESTAMP(CONCAT(?, ' 17:05:00'), 'DD/MM/YYYY HH24:MI:SS')
            and
            TO_TIMESTAMP(CONCAT(?, ' 17:05:00'), 'DD/MM/YYYY HH24:MI:SS')
          ELSE
            (packages.created_at::timestamptz #{utc_offset_to_eval})
            between
            TO_TIMESTAMP(CONCAT(?, ' ', packages.operation_cutting_hour, ':00'), 'DD/MM/YYYY HH24:MI:SS')
            and
            TO_TIMESTAMP(CONCAT(?, ' ', packages.operation_cutting_hour, ':00'), 'DD/MM/YYYY HH24:MI:SS')
          END
      ELSE
        (packages.operation_date::timestamptz)
        between
        TO_TIMESTAMP(?, 'DD/MM/YYYY')
        AND
        TO_TIMESTAMP(?, 'DD/MM/YYYY')
      END
    "
  end

  def webhook_notifications
    WebhookNotification.by_instance(self)
  end

  def check?(type)
    return false if check.blank?

    check.send(type)['created_at']
  end

  def estimated_delivery
    return '' if delivery_time.blank?

    checkout = check?('out')
    return '' unless checkout.present?

    checkout ? delivery_time.to_i.business_days.after(checkout.to_date) : delivery_time.to_i.business_days.after(created_at)
  rescue => e
    Rails.logger.info "ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}".red.swap
    ''
  end

  def create_default_check
    create_check(in: { created_at: DateTime.current,
                       hero: 'Hero Shipit',
                       shipit_code: shipit_code,
                       branch_office_id: branch_office_id,
                       courier: courier_for_client,
                       craftsman: 'pack' }) if check?('in').blank?
  end

  def create_in_trello
    Publisher.publish('mass', Package.generate_template_for(3, [self], company.current_account))
  end

  def ff_series
    return [] if service != 'FF'

    series = FulfillmentService.series_by_package(id)
    return [] if series.to_s.include?('error')

    series
  end

  def warehouse_integration?
    platform == 'warehouse_integration'
  end

  def set_tcc
    return unless courier_for_client.present?

    tcc = Setting.opit(branch_office.company.id).courier_tcc(courier_for_client)
    return unless tcc.present?

    update_columns(tcc: Setting.opit(branch_office.company.id).courier_tcc(courier_for_client))
  rescue => e
    Slack::Ti.new({}, {}).alert('', "PACKAGE#set_tcc LINE 1170: #{e.message} \n #{e.backtrace.join('\n')}")
  end

  def on_time
    return false if operation_date < Date.current
    return true if operation_date > Date.current

    timezone = DateTime.current.strftime("%Z")

    if operation_cutting_hour.present?
      (DateTime.parse('00:00' + timezone)..DateTime.parse(operation_cutting_hour + timezone)).cover?(DateTime.current)
    else
      (DateTime.parse('00:00' + timezone)..DateTime.parse('14:05' + timezone)).cover?(DateTime.current)
    end
  end

  def editable_by_client
    (status == 'created' || status == 'in_preparation') && !company.fulfillment?
  end

  def not_retired
    status == 'pending' && operation_date.present? && !company.fulfillment? && !on_time
  end

  def archivable_by_client
    !is_returned && (editable_by_client || not_retired)
  end

  def returnable_by_client
    status == 'at_shipit' && !company.fulfillment?
  end

  def archive
    Publisher.publish('archived_items', id) if inventory_activity.blank?
    update(is_archive: true)
  end

  def self.select_processed_active
    select('addresses.street AS address_street, addresses.number AS address_number,'\
           'addresses.complement AS address_complement, addresses.commune_id AS address_commune_id,'\
           'insurances.ticket_amount AS insurance_ticket_amount, insurances.extra AS insurance_extra,'\
           'insurances.ticket_number AS insurance_ticket_number, insurances.detail AS insurance_detail,'\
           'checks.in AS in_created_at, packages.branch_office_id, packages.return_created_at,'\
           'packages.automatic_retry_date, packages.comments, packages.full_name, packages.id,'\
           'packages.reference, packages.created_at, packages.status, packages.sub_status, entities.name AS company_name,'\
           'packages.height, packages.width, packages.length, packages.weight, packages.tracking_number,'\
           'packages.courier_for_client, packages.is_returned, packages.cellphone,'\
           'packages.approx_size, packages.volume_price, packages.items_count, packages.position, packages.father_id')
  end

  def self.returned_processed(current_account)
    current_account.current_company.packages.left_outer_joins(:check, :insurance).
      joins(:address, :branch_office, :company, company: :entity, address: :commune).by_status(:in_preparation).
        where(is_returned: true).not_sandbox.not_test
  end

  def self.returned_select(current_account)
    current_account.current_company.packages.left_outer_joins(:check, :insurance).
      joins(:address, :branch_office, :company, company: :entity, address: :commune).by_status(:at_shipit)
        .where.not(return_created_at: nil).not_sandbox.not_test
  end

  def self.returned_history(current_account)
    Package.left_outer_joins(:check, :insurance).
      joins(:address, :branch_office, :company, company: :entity, address: :commune).not_sandbox.not_test.
        where(branch_office_id: current_account.entity_specific.branch_offices.ids).
        where(is_returned: true).or(Package.left_outer_joins(:check, :insurance).joins(:address, :branch_office, :company, company: :entity, address: :commune).
          not_sandbox.not_test.where(status: :at_shipit, branch_office_id: current_account.current_company.branch_offices.ids))
  end

  def self.filter_returned(account, kind = 'processed', per = 50, page = 1)
    shipments =
      case kind
      when 'processed' then returned_processed(account)
      when 'returned' then returned_select(account)
      else
        returned_history(account)
      end
    { shipments: shipments.select_processed_active.order(return_created_at: :desc).page(page).per(per).load,
      total: shipments.size }
  end

  def new_tracking
    return unless courier_for_client.present?

    update_columns(tracking_number: nil, courier_url: nil, url_pack: nil, pack_pdf: nil)
    set_label_size
    set_price
  end

  def whatsapp_template(configuration)
    return 'Servicio no disponible' if branch_office.company_platform_version == 2
    return 'Mensaje ya enviado' if whatsapps.delivered(status)
    return 'Notificacion desactivada o sin numero de telefono disponible' unless configuration.present? || configuration['buyer']['whatsapp']['state'][status]['active'] || cellphone.present?

    { template: WhatsappNotification.find_by(company_id: branch_office.company_id, state: status),
      type: 'whatsapp' }
  end

  def email_template(configuration)
    return 'Alerta ya entregada' if alerts.delivered(status)
    return 'Condiciones de envío no válidas' unless email.present? && email_valid? && tracking_number.present?
    return 'Configuración de estado inactiva' unless configuration['buyer']['mail']['state'][status]['active']

    { template: MailNotification.find_by(company_id: branch_office.company_id, state: status).inject_params,
      type: 'email' }
  end

  def notification_serialize_data
    {
      id: id,
      courier: courier_for_client,
      tracking_number: tracking_number,
      status: status,
      full_name: full_name,
      email: email,
      phone: (cellphone.try(:length) == 9 ? "56#{cellphone}" : cellphone),
      shipit_tracking_url: "https://seguimiento.shipit.cl/statuses?number=#{tracking_number}",
      courier_tracking_url: courier_url,
      reference: reference,
      courier_status: courier_status,
      sub_status: sub_status
    }
  end

  def email_valid?
    email_regexp = /^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/
    email.try(:strip) =~ email_regexp
  end

  def set_label_size
    self.label['size'] = Setting.printers(branch_office.company_id).label_package_size
    update_columns(label: self.label)
  end

  def generate_tracking(company)
    set_label_size
    tracking = Opit.new(self).generate_tracking(Package.generate_template_for(1, [self], company))
    raise 'No se creo tracking' unless tracking.present?

    update_columns(tracking_number: tracking['number'], courier_url: tracking['url_pdf'], url_pack: tracking['url_pack'], pack_pdf: tracking['pack_pdf'])
    Notifications::BuyerNotificationService.dispatch(self, :in_preparation)
  rescue => e
    Slack::Ti.new({}, {}).alert('', "PACKAGE LINE 1220: #{e.message} \n #{e.backtrace.join('\n')}")
  end

  def calculate_total
    prices = Price::Shipment.new(
      subscription: company_current_subscription,
      apply_courier_discount: apply_courier_discount,
      courier_selected: courier_selected,
      total_price: total_price,
      shipping_price: shipping_price,
      shipping_cost: shipping_cost,
      insurance_price: insurance_price,
      material_extra: material_extra,
      is_paid_shipit: is_paid_shipit,
      is_payable: is_payable,
      packing: packing.presence || 'Sin empaque',
      height: height,
      width: width,
      length: length,
      negotiation_amount: negotiation_amount,
      negotiation_kind: negotiation_kind
    ).calculate_prices
    update_columns(total_is_payable: prices[:total_is_payable],
                   material_extra: prices[:material_extra],
                   shipping_price: prices[:shipping_price],
                   shipping_cost: prices[:shipping_cost],
                   total_price: prices[:total_price],
                   negotiation_total: prices[:negotiation],
                   discount_percent: prices[:discount_percent],
                   discount_amount: prices[:discount_amount])
  rescue => e
    Slack::Ti.new({}, {}).alert('', "PACKAGE CAN NOT CALCULATE TOTAL AT LINE 1250: #{e.message} \n #{e.backtrace.join('\n')}")
  end

  def self.select_calendar
    select("packages.delayed, packages.created_at, packages.id, packages.reference, packages.delivery_time,
            packages.courier_for_client, packages.status, packages.sub_status, packages.operation_date, packages.sub_status, packages.tracking_number,
            checks.in ->> 'created_at' AS in_created_at, checks.out ->> 'created_at' AS out_created_at,
            (SELECT COUNT(*) AS tickets_quantity FROM supports WHERE supports.package_id = packages.id AND supports.show_client = true),
            (SELECT row_to_json(sup) as last_ticket FROM (SELECT * FROM supports WHERE supports.package_id = packages.id AND supports.show_client = true ORDER BY created_at DESC LIMIT 1) AS sup)")
  end

  def estimated_price?
    aprox_sizes?
  end

  def aprox_sizes?
    square_size_choose = ((approx_size || '').match(/\d+/).to_s || 10).to_f
    width == square_size_choose && length == square_size_choose && height == square_size_choose
  end

  def print_attributes
    { commune_name: address.try(:commune).try(:name),
      id: id,
      reference: reference,
      courier_for_client: courier_for_client,
      full_name: full_name,
      tracking_number: tracking_number,
      created_at: created_at,
      label_printed: label_printed }
  end

  def set_apply_courier_discount
    update_columns(apply_courier_discount: company_apply_discount)
  end

  def alerts_sent
    return [] if alerts.size.zero?

    alerts.sort_by(&:created_at).reverse.map do |alert|
      { state: alert.state, sent: alert.email_sent }
    end
  end

  def whatsapps_sent
    return [] if whatsapps.size.zero?

    whatsapps.sort_by(&:created_at).reverse.map do |alert|
      { state: alert.state, sent: alert.sent }
    end
  end

  def insurance_price
    insurance.present? ? insurance.price : 0
  end

  def active_insurance
    automatization = Setting.automatization(company.id).configuration['automatizations']['insurance']
    InsuranceService.new(id: id,
                         courier_for_client: courier_for_client,
                         insurance: insurance,
                         platform: platform,
                         company: company,
                         automatization: automatization).active
  end

  def dimensions
    "#{height}x#{width}x#{length}"
  end

  def test?
    reference.to_s.downcase.start_with?('test-') || is_sandbox?
  end

  def available_to_pickup?
    inventory_activity.nil? || !is_returned #|| inverse_logistic?
  end

  def available_to_get_price?
    !is_payable && courier_for_client.blank? && shipping_price.to_i.zero?
  end

  def available_to_get_tracking?
    return false if ['retiro cliente', 'despacho retail'].include?(destiny.downcase)

    courier_for_client.present? && tracking_number.blank? && !(is_payable && destiny.downcase == 'domicilio' && courier_for_client.downcase == 'chilexpress')
  end

  def self.searching(current_account, query, page = 1, per_page = 40)
    search = ElasticService.new(current_account)
    search.shipments(query, page, per_page)
  end

  def request_prediction_delivery_date
    return unless courier_for_client_changed?

    request_delivery_date
  end

  def request_delivery_date
    Publisher.publish('request_delivery_date', { package_id: id })
  end

  def management_transition
    return unless sub_status_changed?

    params = { package_id: id, sub_status: sub_status_change[1] }
    Publisher.publish('management_transition', params)
  end

  def delayed?
    PackageService.apply_delayed_rules(self)
  end

  def manifest_template
    {
      id: id,
      reference: reference,
      tracking_number: tracking_number,
      items_count: items_count,
      full_name: full_name,
      commune: address_commune_id
    }.with_indifferent_access
  end
end
