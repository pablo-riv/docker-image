module HubspotService
  class Contact < HubspotService::Hubspot
    attr_accessor :properties, :errors
    def initialize(properties)
      super(properties)
    end

    def hubspot_properties
      {
        properties: [
          { property: 'email', value: account.email },
          { property: 'company_id', value: company_id },
          { property: 'company', value: company_name },
          { property: 'firstname', value: first_name },
          { property: 'lastname', value: last_name },
          { property: 'website', value: company_website },
          { property: 'envios_totales_realizados', value: total_shipment },
          { property: 'total_daily_average', value: total_daily_average },
          { property: 'last_delivery_day', value: last_delivery_day },
          { property: 'company_state', value: company_state },
          { property: 'comuna2', value: state },
          { property: 'region', value: region },
          { property: 'country', value: country },
          { property: 'sign_in_count', value: sign_in_count },
          { property: 'features', value: features },
          { property: 'setup_percent', value: setup_percent },
          { property: 'package_hope', value: packages_hope },
          { property: 'shipit_created_at', value: created_at },
          { property: 'dni', value: dni },
          { property: 'tickets', value: tickets },
          { property: 'total_support_tickets', value: total_support_tickets },
          { property: 'last_month_sales', value: last_month_sales },
          { property: 'phone', value: phone },
          { property: 'servicio_que_utiliza_contacto', value: current_services },
          { property: 'integrations', value: integrations },
          { property: 'email_contact', value: email },
          { property: 'cuenta_en_shipit', value: shipit_account },
          { property: 'firts_delivery_day', value: firts_delivery_day },
          { property: 'expired_bill', value: expired_bill? },
          { property: 'average_last_six_months', value: average_last_six_months },
          { property: 'last_month_shipments', value: last_month_shipments },
          { property: 'plan', value: plan },
          { property: 'last_monthly_shipments', value: last_monthly_shipments },
          { property: 'accumulate_current_month', value: accumulate_current_month },
          { property: 'role_name', value: 'Comercial' },
          { property: 'owner_70', value: first_owner },
          { property: 'owner_30', value: second_owner },
          { property: 'deactivated', value: deactivated },
          { property: 'deactivation_date', value: deactivation_date },
          { property: 'deactivation_reason', value: deactivation_reason },
          { property: 'deactivation_details', value: deactivation_details }
        ]
      }.with_indifferent_access
    end
  end
end
