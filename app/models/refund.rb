class Refund < ApplicationRecord
  # RELATIONS
  belongs_to :package
  belongs_to :support
  has_one :branch_office, through: :package
  has_paper_trail ignore: [:updated_at]
  has_one :lost_parcel
  has_one :incidence, through: :lost_parcel

  # CALLBACKS OMITTED FOR MIGRATION
  # after_commit :update_package_indemnify_amounts
  # after_create :update_package_attributes

  # VALIDATIONS
  validates_uniqueness_of :package_id
  validates_presence_of :package_id, :motive, :assignee_id, :assignee_type, :responsible, :content_price, :total_refund, :status, :date # invoice_number & comments can be blank
  validates_numericality_of :total_refund, greater_than: 0

  # TYPES
  enum assignee_type: { staff: 0, account: 1 }
  enum motive: { strayed: 0, depletion: 1, damage: 2, exemption: 3, time_barred: 4 }
  enum responsible: {
    shipit: 0,
    chilexpress: 1,
    starken: 2,
    bluexpress: 3,
    motopartner: 4,
    chileparcels: 5,
    ninety_nine_minutes: 6,
    shippify: 7,
    correos_de_chile: 8,
    dhl: 9,
    kp: 10,
    kw: 11,
    pp: 12
  }
  enum status: { pending: 0, approved: 1, rejected: 2, waiting: 3 }

  # SCOPE
  default_scope { where(active: true) }

  # CONSTANTS (Used in migration)
  DISCOUNT_REASONS = {
    'Pieza en poder de remitente' => :depletion,
    'Extraviado' => :strayed,
    'Dañado' => :damage,
    'Excepción' => :exemption
  }.freeze

  DISCOUNT_RESPONSIBLES = {
    0 => :shipit,
    1 => :chilexpress,
    2 => :starken,
    3 => :dhl,
    4 => :ninety_nine_minutes,
    5 => :chileparcels,
    6 => :motopartner,
    7 => :bluexpress,
    8 => :kp,
    9 => :kw,
    10 => :pp,
    11 => :shippify # Originally 8
  }.freeze

  # CLASS METHODS
  def self.by_date(year = Date.current.year, month = Date.current.month, active = true)
    query_string = 'EXTRACT(YEAR FROM refunds.date) = ? AND EXTRACT(MONTH FROM refunds.date) = ? AND refunds.active = ?'
    active ? where(query_string, year, month, active) : unscoped.where(query_string, year, month, active)
  end

  def self.allowed_attributes
    %i[
      package_id invoice_number motive assignee_id assignee_type responsible comments
      content_price shipping_price overcharge_price total_refund support_id status date active
    ]
  end

  def self.created_or_deactivated?(package_id)
    unscoped.find_by(package_id: package_id).present?
  end

  def self.listed_by_company(refunds: [])
    refunds_by_company = {}
    refunds.each do |refund|
      company = refund.branch_office.company
      if refunds_by_company[company.id].present?
        refunds_by_company[company.id][:amount] += refund.total_refund
        refunds_by_company[company.id][:quantity] += 1
      else
        refunds_by_company[company.id] = { company_name: company.name, amount: refund.total_refund, quantity: 1 }
      end
    end
    refunds_by_company.sort_by { |array| array[1][:company_name] }
  end

  def self.from_company(company_id)
    company = Company.find_by(id: company_id)
    raise "Compañía con ID: #{company_id} no encontrada" unless company.present?

    joins(:package).where('packages.branch_office_id IN (?)', company.branch_office_ids)
  rescue StandardError => e
    Rails.logger.error { "ERROR: #{e.message}\nBACKTRACE: #{e.backtrace[0]}".red.swap }
    []
  end

  # INSTANCE METHODS
  def company_name
    package.try(:branch_office_company_name)
  rescue StandardError => _e
    'Sin nombre disponible'
  end

  def branch_office_name
    package.branch_office.name
  rescue StandardError => _e
    package.company_name
  end

  def update_package_indemnify_amounts
    key = responsible == 'shipit' ? 'shipit' : 'courier'
    package.manual_update!({ "#{key}_indemnify" => true, "#{key}_indemnify_amount" => total_refund })
  end

  def update_package_attributes
    package.manual_update!({ status: :indemnify, sub_status: :indemnify }) if content_price.positive?
    package.manual_update!({ is_paid_shipit: true, paid_by_shipit_reason: I18n.t("refunds.motives.#{motive}") }) if shipping_price.positive? || overcharge_price.positive?
  end
end
