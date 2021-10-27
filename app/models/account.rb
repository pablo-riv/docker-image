class Account < ApplicationRecord
  rolify

  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }

  after_create :default_role
  after_create :create_spread_sheet
  after_create :create_zendesk_user
  # Enable API authentication
  acts_as_token_authenticatable

  # RELATIONS
  belongs_to :entity
  belongs_to :person
  has_many :supports
  has_many :drop_outs

  default_scope { where(active: true) }

  delegate :acting_as, to: :entity, prefix: true
  delegate :specific, to: :entity, prefix: true
  delegate :first_name, to: :person, prefix: true, allow_nil: true
  delegate :last_name, to: :person, prefix: true, allow_nil: true
  delegate :phone, to: :person, prefix: true, allow_nil: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :masqueradable

  validates_uniqueness_of :email, case_sensitive: false, allow_blank: true, if: :email_changed?
  validates_format_of :email, with: Devise.email_regexp
  validates_presence_of :email, :password, :password_confirmation, on: :create
  validates_confirmation_of :password
  validates_length_of :password, within: Devise.password_length, allow_blank: true

  accepts_nested_attributes_for :entity
  accepts_nested_attributes_for :person

  attr_accessor :company_name, :company_capture, :seller_email, :company_description, :packages_monthly_range

  def self.validate_account_type_for(_company, branch_office = {})
    branch_office.blank? ? 'company' : 'branch_office'
  end

  def self.allowed_attributes
    [:email, :company_name, :password, :password_confirmation, :how_to_know, :from, :entity_id, :person_id, entity_attributes: [:id], person_attributes: [:first_name, :last_name, :phone]]
  end

  def self.valid_email?(email_address)
    email_regexp = /\A[^@]+@[^@]+\z/
    puts "Valid" if email_address =~ email_regexp
  end

  def self.with_tickets_unsolved
    joins(:supports).where("supports.status IN ('open', 'pending')").distinct('accounts.id')
  end

  def self.select_hack_data
    select('accounts.id AS id, accounts.email, accounts.active, accounts.authentication_token, accounts.suite_sessions, accounts.id_printer, accounts.created_at, accounts.updated_at, p.phone AS account_phone, accounts.entity_id,'\
           'p.first_name AS account_first_name, p.last_name AS account_last_name, c.id AS company_id, e.name AS entity_name, c.active AS company_active, c.debtors AS company_debtors,'\
           'c.first_owner_id AS company_first_owner_id, c.second_owner_id AS company_second_owner_id, c.platform_version AS company_platform_version, c.created_at AS company_created_at,'\
           'c.commercial_flow AS company_commercial_flow, c.administrative_flow AS company_administrative_flow, c.operative_flow AS company_operative_flow, c.plan_flow AS company_plan_flow')
  end

  def last_month_chart
    data = entity_specific.packages.between_dates(Date.current.at_beginning_of_month - 1.month, Date.current.at_end_of_month).
      select('COUNT(packages.*) AS count_all,'\
             'EXTRACT(MONTH FROM packages.created_at::date) AS packages_created_at_month,'\
             'EXTRACT(DAY FROM packages.created_at::date) AS packages_created_at_day').
        group('packages_created_at_month, packages_created_at_day, packages.operation_date').order('EXTRACT(MONTH FROM packages.created_at::date)').
          group_by { |p| I18n.t('date.month_names').compact[p.packages_created_at_month.round - 1] }
    grouped = []
    data.each do |key, value|
      acc = 0
      grouped << { name: key, data: value.sort_by { |v| v.packages_created_at_day.round }
                                         .map { |p| [p.packages_created_at_day.round, (acc += p.count_all; acc)] } }
    end
    grouped
  end

  def total_saved_time
    (((entity_specific.packages.count * 6.minutes) / 1.minutes).minutes / 60)
  end

  def most_packing_used
    packings = entity_specific.packages.pluck(:packing)
    packings.compact.max
  end

  def best_day_of_week
    best_day = entity_specific.packages.map { |package| package.created_at.strftime('%A')}.compact
    return [] if best_day.blank?
    Hash[best_day.group_by(&:itself).map {|day, value| [day, value.size] }].max_by {|v| v.size}.first
  end

  def prices_by_package
    entity_specific.packages.includes(address: { commune: :region }).select(:id, :created_at, :reference, :full_name, :total_price, :status, :courier_for_client, :tracking_number, :sub_status)
  end

  def full_name
    "#{person.try(:first_name)} #{person.try(:last_name)}"
  end

  def current_company
    has_role?(:owner) ? entity_specific : entity_specific.company
  end

  def current_branch_office
    has_role?(:owner) ? entity_specific.branch_offices.first : entity_specific
  end

  def generate_relation(params = {})
    person = params.blank? ? create_person : create_person(params)
    person if person.save(validate: false)
  end

  def default_role
    entity = self.entity
    if entity.actable_type == 'Company'
      add_role :owner
    else
      add_role :employee
    end
  end

  def serialize_data!
    entity_params = { include: { address: { include: :commune },
                                 branch_offices: { include: { address: { include: :commune }, entity: { include: :accounts }, hero: { include: :person } } } } }
    company_params = { billing_address: { include: :commune },
                       services: {},
                       settings: { include: :service } }
    params = entity.actable_type == 'Company' ? entity_params[:include].merge(company_params) : entity_params[:include].except!(:branch_offices)
    data = serializable_hash(include: { person: {}, entity_specific: { include: params } })
    if entity.actable_type == 'Company'
      data['entity_specific']['branch_offices'].map do |branch_office|
        account = branch_office['entity']['accounts'][0] || {}
        branch_office['account'] = account
        branch_office.except!('entity')
      end
    end
    data
  end

  def create_spread_sheet
    SpreadsheetsJob.perform_later(self, 'V6') if Rails.env.production?
  end

  def is_new_courier_price_enabled?
    configuration = entity_specific.settings.find_by(service_id: 1)['configuration']
    !configuration['opit']['is_new_courier_price_enabled'].nil? && configuration['opit']['is_new_courier_price_enabled'] == true
  end

  def create_zendesk_user
    support = Help::ZendeskUser.new(self)
    support.find
    begin
      support.create unless support.user.present?
      update(zendesk_id: support.user.id)
    rescue => e
      puts "EXCEPTION: #{e.message}".red.swap
    end
  end

  def send_token_code
    code = 4.times.map { rand(0..9) }.join('')
    ResetPasswordMailer.code(self, code).deliver
    code
  end

  def current_negotiation
    current_company.negotiation
  end

  def current_google_spreadsheet_link
    current_branch_office.google_sheet_link
  end
end
