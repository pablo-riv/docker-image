class Company < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }

  ## CALLBACKS
  after_create :warn_staff
  after_create :create_base_packing
  after_create :upload_default_logo
  after_commit :send_to_elastic

  ## RELATIONS
  has_many :settings, dependent: :destroy
  has_many :services, through: :settings
  has_many :branch_offices, dependent: :destroy
  has_many :packages, through: :branch_offices
  has_many :manifests, through: :branch_offices
  has_many :charges
  has_many :fines, through: :branch_offices
  has_many :mail_notifications
  has_many :whatsapp_notifications
  has_many :prints
  has_many :packings
  has_many :products
  has_many :address_books
  has_many :returns, through: :address_books, source: :addressable, source_type: 'Return'
  has_many :origins, through: :address_books, source: :addressable, source_type: 'Origin'
  has_many :destinies, through: :address_books, source: :addressable, source_type: 'Destiny'
  has_many :insurances, through: :packages
  has_many :orders
  has_many :companies_features
  has_many :features, through: :companies_features
  has_many :subscriptions
  has_many :plans, through: :subscriptions
  has_many :apps, through: :subscriptions, source: :apps_collections
  has_many :contacts
  has_many :invoices
  has_many :downloads
  has_many :suite_notifications
  has_many :bsale_webhooks
  has_many :pickups, through: :branch_offices
  has_many :kpis, as: :kpiable
  has_many :supports
  has_one :negotiation
  has_one :cutting_hour, as: :cutting
  belongs_to :partner, optional: true
  belongs_to :acquisition_segment, class_name: 'CompanySegment', foreign_key: :acquisition_segment_id
  belongs_to :retention_segment, class_name: 'CompanySegment', foreign_key: :retention_segment_id

  default_scope { where(active: true) }

  accepts_nested_attributes_for :packages
  accepts_nested_attributes_for :settings

  store :cutting_hours, accessors: %i(pp ff ll)

  ## ACT AS ENTITY
  acts_as :entity

  ## DELEGATORS
  delegate :kind, to: :negotiation, allow_nil: :false, prefix: 'negotiation'
  delegate :percent, to: :negotiation, allow_nil: :false, prefix: 'negotiation'
  delegate :amount, to: :negotiation, allow_nil: :false, prefix: 'negotiation'
  delegate :recurrent, to: :negotiation, allow_nil: :false, prefix: 'negotiation'

  ## VALIDATIONS
  validates_presence_of :name, :run, on: :update
  has_attached_file :logo, styles: { large: '1920x1080>', medium: '1280x720>', small: '480x340>', thumb: '50x50>' }, default_url: ':style/missing.jpeg'
  validates_attachment :logo, content_type: { content_type: 'image/png' }

  ## PUBLIC METHODS

  default_scope { where(active: true) }

  def self.querying(params, current_account)
    Package.searching(current_account, params[:s][:q], params[:page], 40)
  end

  def self.allowed_attributes
    [:name, :run, :website, :email_domain, :commercial_business, :phone, :logo, :about,
     :email_contact, :contact_name, :is_active, :is_default, :email_notification, :email_commercial,
     :logo, :term_of_service, :know_size_restriction, :know_base_charge, :business_name,
     :business_turn, :bill_email, :bill_phone, :bill_address, :capture,
     preferences: [email: { color: [:background_header, :background_footer, :font_color_footer], text: [] }],
     sales_channel: [names: [:name], categories: [:category]], packages_attributes: [], settings_attributes: []]
  end

  def self.setup(params, current_account)
    company = current_account.entity.specific
    branch_office = company.default_branch_office
    company_params = { name: params['company']['name'],
                       run: params['company']['run'],
                       phone: params['company']['phone'],
                       website: params['company']['website'],
                       email_notification: params['company']['email_notification'],
                       email_contact: params['company']['email_contact'],
                       business_turn: params['company']['business_turn'],
                       business_name: params['company']['business_name'],
                       bill_email: params['company']['bill_email'],
                       bill_phone: params['company']['bill_phone'],
                       bill_address: params['company']['bill_address'],
                       term_of_service: true,
                       know_size_restriction: true,
                       know_base_charge: true,
                       contact_name: "#{params['person']['first_name']} #{params['person']['last_name']}" }
    branch_office_params = { name: "#{params['company']['name']} Casa Matriz",
                             parking_isreachable: params['company']['branch_office']['parking_isreachable'],
                             get_to_parking: params['company']['branch_office']['get_to_parking'],
                             contact_name: "#{params['person']['first_name']} #{params['person']['last_name']}",
                             phone: params['company']['phone'] }
    person_params = { phone: params['company']['phone'],
                      first_name: params['person']['first_name'],
                      last_name: params['person']['last_name'] }
    return false unless current_account.person.update_columns(person_params)

    address_params = { street: params['company']['address']['street'],
                       number: params['company']['address']['number'],
                       complement: params['company']['address']['complement'],
                       commune_id: params['company']['address']['commune_id'] }
    current_account.entity.update_address(address_params, branch_office)
    new().create_or_update_origin(current_account, company, current_account.entity.address)
    company.update!(company_params) && branch_office.update!(branch_office_params)
  end

  def self.search_by_integration_info(integration, criteria = '', value = '')
    return if integration.blank?

    settings = Setting.where(service_id: 2).select do |setting|
      setting.configuration['fullit']['sellers'].find { |w| w.keys.first == integration }
             .values.first[criteria].to_s.include?(value)
    end

    settings.map(&:company)
  end

  def generate_relation
    branch_office = branch_offices.create(name: "#{name} Casa Matriz", is_default: true)
    settings.create([{ service_id: 3 }, { service_id: 2 }, { service_id: 6 }, { service_id: 1 }, { service_id: 7 }, { service_id: 8 }, { service_id: 9 }]) if branch_office.save(validate: false)
    create_negotiation(kind: :amount)
    generate_default_buyer_notifications if settings.find_by(service_id: 6).present?
  end

  def send_new_company(_method = 'new')
    { company: serializable_hash(include: [:address, :billing_address, :branch_offices, :settings]) }
  end

  def charges_summary(year, month)
    company_packages = packages.by_billing_date(year, month).not_sandbox.not_test

    if company_packages.empty?
      paid_by_shipit = 0
      returns = 0
      shipments = 0
      total_is_payable = 0
      material_extra = 0
    else
      # package dependent calcs
      paid_by_shipit = company_packages.paid_by_shipit.sum(:total_price)

      packages = company_packages.no_paid_by_shipit
      returns = packages.returned.sum(:shipping_price)
      shipments = packages.no_returned.sum(:shipping_price)
      total_is_payable = packages.sum(:total_is_payable)
      material_extra = packages.sum(:material_extra)
    end

    # independent from packages
    company_fines = fines.pickup_failed.by_date(year, month).sum(:amount)
    parking = fines.parking.by_date(year, month).sum(:amount)
    discounts = fines.discounts.by_date(year, month).sum(:amount)
    base_charge = charges.by_date(year, month).where("charges.details ->> 'type' = 'base_charge_pp'")
    base = base_charge.blank? ? 0 : base_charge[0].details['amount']
    premium = charges.premium.by_date(year, month).sum("CAST(charges.details ->> 'amount' AS INTEGER)")
    recurrent_charge = charges.opit.by_date(year, month).where("charges.details ->> 'type' = 'recurrent_charge'").sum("CAST(charges.details ->> 'amount' AS INTEGER)")
    total = (premium + recurrent_charge + base + company_fines + parking + total_is_payable + returns + shipments + material_extra - discounts).round

    {
      packages_count: company_packages.size,
      name: name,
      fines: company_fines,
      returns: returns.round,
      shipments: shipments.round,
      material_extra: material_extra.round,
      paid_by_shipit: paid_by_shipit.round,
      parking: parking.round,
      discounts: discounts.round,
      base: base.round,
      recurrent_charge: recurrent_charge,
      premium: premium,
      total_amount: total.round,
      total_is_payable: total_is_payable.round
    }
  end

  def default_branch_office
    branch_offices.find_by(is_default: true)
  end

  def default_account
    accounts.first
  end

  def fulfillment_settings
    settings.find_by(service_id: 4)
  end

  def notification_settings
    settings.find_by(service_id: 6)
  end

  def current_account
    Account.find_by(entity_id: acting_as.id)
  end

  def webhook_pp_available
    web = Setting.where("settings.service_id = 3 AND settings.company_id = ? AND settings.configuration -> 'pp' -> 'webhook' -> 'package' ->> 'url' <> ''", id).
      select("settings.configuration -> 'pp' -> 'webhook' -> 'package' ->> 'url' AS hook").first
    web.try(:hook)
  end

  def fulfillment?
    fulfillment_settings.present?
  end

  def warn_staff
    NewUserMailer.user_created(self).deliver
  end

  def initials
    str = ''
    name.split(' ').each { |n| str += n.first }
    str
  end

  def any_integrations?
    active = false
    Setting.fullit(id).configuration['fullit']['sellers'].each do |seller|
      active = true unless (seller.values.first['client_id'].blank? && seller.keys.first != 'bootic') || (seller.keys.first == 'bootic' && seller.values.first['authorization_token'].blank?)
    end
    active
  rescue
    false
  end

  def integrations_activated
    settings = Setting.fullit(id).configuration['fullit']['sellers'].map do |seller|
      seller.keys.first unless (seller.values.first['client_id'].blank? && %w(bootic bsale).all? { |name| name != seller.keys.first }) || (seller.keys.first == 'bootic' && seller.values.first['authorization_token'].blank?) || (seller.keys.first == 'bsale' && seller.values.first['client_secret'].blank?)
    end
    settings.compact
  rescue
    []
  end

  def tracking_notification?
    Setting.notification(id).configuration['notification']['to_buyer']
  rescue
    false
  end

  def sandbox?
    Setting.pp(id).configuration['pp']['sandbox']
  end

  def generate_default_buyer_notifications
    %w[in_preparation in_route delivered failed by_retired].each_with_index do |state, index|
      mail_notifications.create(tracking: true, state: index)
      whatsapp_notifications.create(state: index)
    end
  end

  def update_preference(params)
    data =
      if params[:logo].include?('shipit-platform.s3.amazonaws.com')
        { preferences: params.to_unsafe_h[:preferences] }
      else
        image = Paperclip.io_adapters.for(params[:logo])
        image.original_filename = "company_#{name}.png"
        { logo: image, preferences: params.to_unsafe_h[:preferences] }
      end
    update!(data)
  end

  def upload_default_logo
    return if Rails.env.development? || Rails.env.test?

    UploadDefaultLogoJob.perform_now(self)
  end

  def couriers_availables
    opit = Setting.opit(id)
    return [] if opit.blank?

    opit.configuration['opit']['couriers'].map { |courier| Courier.achronim_to_name(courier.keys.first) if courier.values.first['available'] }
  end

  def apply_discount
     (%w[chilexpress starken muvsmart chileparcels motopartner bluexpress] - couriers_availables.compact).size.zero?
  end

  def default_mailing_list
    bcc = []
    bcc.push(entity.email_contact) unless entity.email_contact.blank?
    entity.email_notification.split(',').each { |mail| bcc.push(mail) unless mail.blank? } unless entity.email_notification.blank?
    bcc
  end

  def integrate_hubspot
    generator = HubspotService::Generator.new(company: self, account: self.current_account)
    generator.create
  rescue => e
    Slack::Ti.new({}, {}).alert('', "Cliente #{name} No pudo actualizar en Hubspot: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
  end

  def create_or_update_origin(current_account, company, address)
    if company.origins.size.zero?
      origin = company.origins.new(
        name: 'default',
        address_book_attributes: {
          company_id: company.id,
          full_name: current_account.full_name,
          phone: company.default_branch_office.phone,
          email: current_account.email,
          default: true,
          address_attributes: address.dup.attributes.except('id', 'created_at', 'updated_at')
        },
        branch_office_id: company.default_branch_office.id
      )
      raise unless origin.save
    else
      origin = company.origins.joins(:address_book).find_by(address_books: { default: true })
      origin.address_book.address.update_columns(address.dup.attributes.except('id', 'created_at', 'updated_at'))
    end
  end

  def active_service
    service = settings.where(service_id: [3, 4]).order(service_id: :asc).map { |s| { name: s.service_name, configuration: s.configuration } }.last
    case service[:name]
    when 'pp' then { name: 'pick_and_pack', configuration: service[:configuration]['pp'] }
    when 'fulfillment' then { name: 'fulfillment', configuration: service[:configuration]['fulfillment'] }
    else
      { name: 'labelling', configuration: service[:configuration]['labelling'] }
    end
  end

  def seller_configuration(seller)
    integration = settings.find_by(service_id: 2).seller_configuration(seller)
    { name: integration.keys.first, configuration: HashWithIndifferentAccess.new(integration[integration.keys.first]) }
  rescue => e
    { name: '', configuration: {} }
  end

  # Not all clients have Return type of Address Book
  def warehouse_default_origin
    { origin: 'LAS CONDES',
      commune: 'LAMPA',
      street: 'El Roble',
      number: 970,
      complement: 'Oficina/Bodega 21',
      phone: '' }
  end

  def default_origin(kind = 'Origin')
    address_book = address_books.find_by(default: true, addressable_type: kind)
    return warehouse_default_origin unless address_book.present?

    { street: address_book.address_street,
      number: address_book.address_number,
      complement: address_book.address_complement,
      commune_id: address_book.address_commune_id,
      commune: address_book.address.commune.name,
      full: "#{address_book.address_street} #{address_book.address_number}, #{address_book.address_commune_name.titleize}, Región #{address_book.address_commune_region_name.titleize}, Chile",
      full_name: address_book.full_name,
      email: address_book.email,
      phone: address_book.phone,
      store: false,
      name: 'default' }
  end

  def default_origin_serialized
    address_books.find_by(default: true, addressable_type: 'Origin').address.serialize_data!
  end

  def current_subscription
    subscriptions.find_by(is_active: true)
  end

  def create_base_packing
    packings.create([{ name: '10x10x10 y 3kg', sizes: {  width: 10, height: 10, length: 10 }, weight: 3, default: true },
                     { name: '30x30x30 y 6kg', sizes: {  width: 30, height: 30, length: 30 }, weight: 6, default: false },
                     { name: '50x50x50 y 9kg', sizes: {  width: 50, height: 50, length: 50 }, weight: 9, default: false },
                     { name: '60x60x60 y 20kg', sizes: { width: 60, height: 60, length: 60 }, weight: 20, default: false }])
  end

  def update_latitude_and_longitude_to_origin(coords)
    origins.joins(:address_book).find_by(address_books: { default: true })
      .address_book.address.update_columns(coords)
  end

  def default_address
    platform_version == 2 ? address : address_books.find_by(default: true, addressable_type: 'Origin').address
  end

  def setup_percent
    commercial = commercial_flow.present? ? 1 : 0
    administrative = administrative_flow.present? ? 1 : 0
    operative = operative_flow.present? ? 1 : 0
    plan = plan_flow.present? ? 1 : 0
    ([commercial, administrative, operative, plan].sum.to_f / 4) * 10
  end

  def notification_serialize_data
    { color_background_header: preferences['email']['color']['background_header'],
      background_footer: preferences['email']['color']['background_footer'],
      font_color_footer: preferences['email']['color']['font_color_footer'],
      name: name,
      logo: logo.url(:medium).gsub('//shipit-platform.s3', 'https://shipit-platform.s3-us-west-2'),
      website: website }
  end

  def default_return_address
    returns.find_by(name: 'default')&.address_book&.address
  end

  def backoffice_couriers_enabled?
    configuration = settings.find_by(service_id: 1)['configuration']
    is_backoffice_couriers_enabled = configuration.dig('opit', 'is_backoffice_couriers_enabled')
    is_backoffice_couriers_enabled.present? && is_backoffice_couriers_enabled == true
  end

  def get_country
    address_books.find_by(default: true, addressable_type: 'Origin').present? ? default_address.commune.region.country : address.commune.region.country
  end
end
