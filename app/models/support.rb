class Support < ApplicationRecord
  ORGANIZATIONS_RESTRICTED = [368_057_510_733, 360_017_095_873, 368_057_518_813, 360_066_274_133, 360_017_099_074].freeze
  HIDE_TICKET_BY_REQUESTER_TYPE = %w[courier final_recipient kam warehouse other_providers other_agent no_asignado].freeze
  # RELATIONS
  belongs_to :account
  belongs_to :package
  belongs_to :company
  has_one :customer_satisfaction

  # CALLBACKS
  before_create :inject_defaults, unless: %i[from_zendesk]
  after_create :generate_zendesk_support, unless: %i[from_zendesk]
  after_create :request_status, unless: %i[from_zendesk]
  after_commit :show_or_hide?
  after_save :request_csat

  default_scope { where(show_client: true) }

  enum requester_type: {
    courier: 0,
    shipit_client: 1,
    final_recipient: 2,
    kam: 3,
    warehouse: 4,
    other_providers: 5,
    other_agent: 6,
    no_asignado: 7
  }

  def self.allowed_attributes
    [:requester_type, :package_id, :subject, :priority, :kind, :account_id, :other_subject, :package_reference, :package_tracking, :last_response_name, :last_response_date, :from_zendesk, messages: [:user, :name, :created_at, :message]]
  end

  def self.zendesk_allowed_attributes
    %i[id package_id subject priority kind account_id other_subject package_reference package_tracking status url assignee_id assignee_email via requester_phone from_zendesk provider_id organization_name requester_type requester_email ticket_description ticket_group_name satisfaction_current_rating satisfaction_current_comment type_query_error]
  end

  def self.between_dates(from, to)
    where(created_at: (from.to_date.at_beginning_of_day..to.to_date.at_end_of_day))
  end

  private

  def generate_zendesk_support
    return true if provider_id.present?
    return true if account_id == 4021

    package = account.current_company.packages.find_by(filter_values)
    ticket = Help::ZendeskTicket.new(subject: subject,
                                     account: account,
                                     message: messages[0]['message'],
                                     company: account.entity_specific,
                                     package: package,
                                     internal_id: id,
                                     other_subject: other_subject,
                                     requester_type: requester_type).create
    update!(package_id: package.try(:id),
            provider_id: ticket.id,
            ticket_id: ticket.id.to_i,
            url: ticket.url,
            via: ticket.via[:channel],
            status: ticket.status,
            priority: ticket.priority,
            kind: I18n.t("helps.type.#{ticket.type}"))
  end

  def inject_defaults
    self.last_response_date = DateTime.current
    self.last_response_name = account.full_name
    self.messages[0]['name'] = account.full_name if self.messages[0].present?
  end

  def request_status
    return unless package_tracking.present?
    return unless account_id == 4021

    branch_offices = account.current_company.branch_offices.ids
    branch_offices unless branch_offices.present?

    package = Package.find_by(branch_office_id: branch_offices, tracking_number: package_tracking)
    response = Opit.get_status(package)
    Rails.logger.info "STATUS RESPONSE: #{response}".cyan.swap
  end

  def show_or_hide?
    update_columns(show_client: show_client?)
  end

  def show_client?
    organization_allowed? && requester_allowed?
  end

  def organization_allowed?
    Support::ORGANIZATIONS_RESTRICTED.count == (Support::ORGANIZATIONS_RESTRICTED - messages.pluck('organization_id')).count
  end

  def requester_allowed?
    Support::HIDE_TICKET_BY_REQUESTER_TYPE.exclude?(requester_type)
  end

  def filter_values
    Hash[*{tracking_number: package_tracking, id: package_id, reference: package_reference}.compact.first]
  end

  def request_csat
    return unless status_changed? # ActiveRecord::Dirty change in rails 5.1+
    return unless %w[solved resuelto].include? status&.downcase
    return if customer_satisfaction.present?

    create_customer_satisfaction
  end
end
