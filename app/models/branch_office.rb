class BranchOffice < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }
  require 'google_drive'

  ## CALLBACKS
  after_create :generate_relation
  after_commit :send_to_elastic

  store :cutting_hours, accessors: %i(pp ff ll)

  ## RELATIONS
  belongs_to :company
  has_many :packages
  has_many :fines
  has_many :pickups, through: :packages
  has_one :location
  has_one :area, through: :location
  has_one :distribution_center, through: :area
  has_one :hero, through: :location
  has_one :origin
  has_one :cutting_hour, as: :cutting

  default_scope { where(active: true) }

  accepts_nested_attributes_for :company
  accepts_nested_attributes_for :packages
  ## ACT AS ENTITY
  acts_as :entity

  delegate :couriers_availables, to: :company
  delegate :platform_version, to: :company, prefix: 'company'
  delegate :current_subscription, to: :company, prefix: 'company'
  delegate :apply_discount, to: :company, prefix: 'company'
  delegate :name, to: :company, prefix: 'company'
  delegate :default_return_address, to: :company, prefix: 'company'

  def self.allowed_attributes
    [:name, :phone, :contact_name, address_attributes: [:street, :number, :complement, :commune_id], accounts_attributes: [:email, :password, :password_confirmation, person: [:first_name, :last_name]]]
  end

  def self.searching(current_account, query, page = 1, per_page = 40)
    search = ElasticService.new(current_account)
    search.branch_offices(query, page, per_page)
  end

  def self.marketplace_request(account, params)
    NewUserMailer.marketplace_request(account, params).deliver
  end

  def self.serialize_data!
    includes(:accounts).map do |branch_office|
      JSON.parse(branch_office.to_json).merge(address: branch_office.default_address.serialize_data!,
                                              account: branch_office.default_account)
    end
  end

  def self.build_branch_office_account(params, company, type = 'new', with_return = false)
    params = JSON.parse(params)

    if with_return
      raise 'Invalid mail format' unless params['account']['email'].match(URI::MailTo::EMAIL_REGEXP).present?
    end

    branch_office_params = { name: params['name'],
                                          contact_name: params['contact_name'],
                                          phone: params['phone'] }
    branch_office =
      if type == 'new'
        create!(branch_office_params.merge(company_id: company.id))
      else
        b = find(params['id'])
        b.update!(branch_office_params)
        b
      end
    person = params['account']['person']
    account =
      if type == 'new'
        branch_office.acting_as.accounts.new(params['account'].except!('person'))
      else
        a = branch_office.accounts.find(params['account']['id'])
        a.update!(params['account'].except!('person', 'entity_specific'))
        a
      end
    person =
      if type == 'new'
        account.create_person(person)
      else
        account.person.update!(person)
        account.person
      end
    account.person_id = person.id
    branch_office.acting_as.address.update_columns(street: params['address']['street'],
                                                   number: params['address']['number'],
                                                   commune_id: params['address']['commune_id'],
                                                   complement: params['address']['complement'])
    raise unless account.save!
    CheckAreaBranchOfficeJob.perform_later(branch_office)
    branch_office if with_return
  end

  def default_account
    acting_as.accounts.first.try(:serialize_data!)
  end

  def create_account(params = {})
    acting_as.accounts.build(params)
  end

  def generate_relation
    return false if Rails.env.test?

    create_location(area_id: Area.first.id, hero_id: 1) unless location.present?
  end

  def full_address
    default_address.full
  rescue NoMethodError => e
    NotifyMailer.without_address(company.specific.accounts.first['email']).deliver # OPTIMIZE: accounts as a hash?
    puts e.message.to_s.red
  end

  def sandbox?
    Setting.pp(company.id).configuration['pp']['sandbox']
  end

  def generate_trello_card
    Sneakers::logger.info "generation trello_card for: #{self.id}".blue
    current_account = company.accounts.first
    data = packages.today_packages_with_exception
    payload = Package.generate_template_for(3, data, current_account)
    temp_datetime = DateTime.current + 5.minutes
    temp_operation_cutting_hour = temp_datetime.strftime('%H:%M')
    payload[:packages].map! { |package| package['operation_cutting_hour'] = temp_operation_cutting_hour; package; }
    Publisher.publish('mass', payload)
  end

  def default_origin
    address_book = origin.address_book
    { street: address_book.address_street,
      number: address_book.address_number,
      complement: address_book.address_complement,
      commune_id: address_book.address_commune_id,
      full: "#{address_book.address_street} #{address_book.address_number}, #{address_book.address_commune_name.titleize}, Región #{address_book.address_commune_region_name.titleize}, Chile",
      full_name: address_book.full_name,
      email: address_book.email,
      phone: address_book.phone,
      store: false,
      name: 'default' }
  end

  def default_origin_serialized
    origin.address_book.address.serialize_data!
  end

  def update_latitude_and_longitude_to_origin(coords)
    default_address.update_columns(coords)
  end

  def default_address
    company_platform_version == 2 ? address : origin.address_book.address
  rescue => _e
    address
  end

  def unique_pickups
    Pickup.includes(:packages).where(packages: { branch_office_id: id })
  end
end
