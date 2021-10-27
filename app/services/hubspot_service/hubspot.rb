module HubspotService
  class Hubspot
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def hubsport_properties
      raise Error::NotImplemented
    end

    def company
      @properties[:company]
    end

    def account
      @properties[:account]
    end

    def drop_out
      @properties[:drop_out].try(:attributes) || {}
    end

    def shipit_account
      account.present? ? 'Si' : 'No'
    end

    def total_shipment
      company.packages.count
    end

    def last_month_shipments
      company.packages.by_date((Date.current - 1.months).at_beginning_of_month.month).count
    end

    def accumulate_current_month
      company.packages.where(created_at: Date.current.at_beginning_of_month..Date.current.at_end_of_day).count
    end

    def last_monthly_shipments
      company.packages.where(created_at: (Date.current - 30.days).at_beginning_of_day..Date.current.at_end_of_day).count
    end

    def average_last_six_months
      shipments_count = company.packages.where(created_at: ((Date.current.at_beginning_of_month - 6.months)..(Date.current.at_end_of_month - 1.month))).count
      return 0 if shipments_count.zero?

      shipments_count / 6
    end

    def total_daily_average
      total_shipments = company.packages
      return 0 if total_shipments.size.zero?

      total_days_active = (company.packages.first.created_at.to_date.step(total_shipments.last.created_at.to_date, 5).count * 5).round
      return 0 if total_days_active.zero?

      total_shipments.size / total_days_active
    end

    def last_delivery_day
      last_shipment = company.packages.last.try(:created_at)
      last_shipment.present? ? last_shipment.to_date.strftime('%Q').to_i : ''
    end

    def firts_delivery_day
      first_shipment = company.packages.first.try(:created_at)
      first_shipment.present? ? first_shipment.to_date.strftime('%Q').to_i : ''
    end

    def company_state
      return 'Dudor' if company.debtors
      return 'Activo' unless company.active && company.packages.last.try(:created_at).present?

      'Inactivo'
    end

    def expired_bill?
      company.expired_bill
    end

    def plan
      company.try(:current_subscription).try(:plan_name)
    end

    def company_name
      company.name
    end

    def company_id
      company.id
    end

    def company_website
      company.website || ''
    end

    def current_services
      settings = company.settings.where(service_id: [3, 4, 10])
      return 'Fulfillment' if settings.find { |s| s.service_id == 4 }.present?
      return 'Labelling' if settings.find { |s| s.service_id == 10 }.present?
      return 'Pick & Pack' if settings.find { |s| s.service_id == 3 }.present?

      'Sin servicio activo'
    end

    def first_name
      account.person_first_name
    end

    def last_name
      account.person_last_name
    end

    def dni
      company.run || ''
    end

    def email
      emails = [account.email]
      emails.concat(company.email_contact.gsub(' ', '').split(',')) if company.email_contact.present?
      emails.join(',')
    end

    def email_domain
      company.email_domain || '@not_found'
    end

    def phone
      company.default_branch_office.phone || '+569'
    end

    def state
      company.address.commune.name.titleize
    rescue => e
      'Sin Comuna'
    end

    def region
      company.address.commune.region.name.titleize
    rescue => e
      'Sin Region'
    end

    def country
      company.address.commune.region.country.name.titleize
    rescue => e
      'Sin Pais'
    end

    def packages_hope
      company.packages_hope || 59
    end

    def first_owner
      ::Salesman.find_by(id: company.first_owner_id).try(:full_name) || 'Sin KAM asignado'
    end

    def second_owner
      ::Salesman.find_by(id: company.second_owner_id).try(:full_name) || 'Sin KAM asignado'
    end

    def last_month_sales
      orders = company.orders.by_date(year: (Date.current.at_beginning_of_month - 1.month).year, month: (Date.current.at_beginning_of_month - 1.month).month).sum_sales[0]
      return 0 unless orders.sum_all.try(:nil?)

      orders.sum_all.try(:round)
    end

    def created_at
      company.created_at.to_date.strftime('%Q').to_i
    end

    def features
      'notifications;support' #company.features.pluck(:name).join(', ')
    end

    def sign_in_count
      account.try(:sign_in_count)
    end

    def setup_percent
      company.setup_percent
    rescue => e
      0
    end

    def integrations
      company.integrations_activated.join(';')
    end

    def tickets
      ''
    end

    def total_support_tickets
      account.supports.size
    end

    def email_contact
      # collect all emails of company
      company.email_contact.present? ? company.email_contact.gsub(' ', '') : ''
    end

    def deactivated
      drop_out['deactivated'] || false
    end

    def deactivation_date
      drop_out['created_at'].to_date.strftime('%Q').to_i
    rescue => e
      ''
    end

    def deactivation_reason
      drop_out['other_reason'] || drop_out['reason'] || ''
    end

    def deactivation_details
      drop_out['details'] || ''
    end
  end
end

