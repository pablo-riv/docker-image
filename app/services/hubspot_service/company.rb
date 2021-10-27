module HubspotService
  class Company < HubspotService::Hubspot
    attr_accessor :properties, :errors
    def initialize(properties)
      super(properties)
    end

    def hubspot_properties
      {
        properties: [
          { name: 'company_id', value: company_id },
          { name: 'name', value: company_name },
          { name: 'website', value: company_website },
          { name: 'total_shipments', value: total_shipment },
          { name: 'total_daily_average', value: total_daily_average },
          { name: 'last_delivery_day', value: last_delivery_day },
          { name: 'company_state', value: company_state },
          { name: 'state', value: state },
          { name: 'region', value: region },
          { name: 'country', value: country },
          { name: 'sign_in_count', value: sign_in_count },
          { name: 'features', value: features },
          { name: 'setup_percent', value: setup_percent },
          { name: 'email_domain', value: email_domain },
          { name: 'packages_hope', value: packages_hope },
          { name: 'shipit_created_at', value: created_at },
          { name: 'kam', value: first_owner },
          { name: 'dni', value: dni },
          { name: 'tickets', value: tickets },
          { name: 'total_support_tickets', value: total_support_tickets },
          { name: 'last_month_sales', value: last_month_sales },
          { name: 'email', value: email },
          { name: 'phone', value: phone },
          { name: 'current_services', value: current_services },
          { name: 'integrations', value: integrations },
          { name: 'email_contact', value: email_contact },
          { name: 'cuenta_en_shipit', value: shipit_account },
          { name: 'firts_delivery_day', value: firts_delivery_day },
          { name: 'expired_bill', value: expired_bill? },
          { name: 'average_last_six_months', value: average_last_six_months },
          { name: 'last_month_shipments', value: last_month_shipments },
          { name: 'plan', value: plan },
          { name: 'last_monthly_shipments', value: last_monthly_shipments },
          { name: 'accumulate_current_month', value: accumulate_current_month },
          { name: 'deactivated', value: deactivated },
          { name: 'deactivation_date', value: deactivation_date },
          { name: 'deactivation_reason', value: deactivation_reason },
          { name: 'deactivation_details', value: deactivation_details }
        ]
      }.with_indifferent_access
    end
  end
end
