module Subscriptions
  class TakesOffPlan
    attr_accessor :properties, :errors

    def self.template
      new(functionalities: nil,
          prirces: nil,
          operations: nil,
          configurations: nil,
          applications: nil,
          charging_frequency: nil).template
    end

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def template
      { company_id: properties[:company_id],
        plan_id: 2,
        is_active: is_active?,
        agreement_date: agreement_date,
        expiration_date: expiration_date,
        charging_frequency: charging_frequency,
        prices: prices,
        functionalities: functionalities,
        operations: operations,
        configurations: configurations,
        application_list: applications,
        integrations: integrations }
    end

    def prices
      # NOTE: PLAN AND SUBSCRIPTION ISN'T AVAILABLE YET
      { total_discount: 0.0, price_per_shipment: 0.0, floor_price: 0.0 }
    end

    def price_per_shipment
      return 0.0 unless properties[:prices].present?

      properties[:prices][:price_per_shipment].presence || 0.0
    end

    def floor_price
      return 0.9 unless properties[:prices].present?

      properties[:prices][:floor_price].presence || 0.9
    end

    def total_discount
      return 4.0 unless properties[:prices].present?

      properties[:prices][:total_discount].presence || 4.0
    end

    def functionalities
      properties[:functionalities].presence || functionalities_template
    end

    def operations
      properties[:operations].presence || operations_template
    end

    def configurations
      properties[:configurations].presence || configurations_template
    end

    def applications
      properties[:applications].presence || apps_template
    end

    def is_active?
      properties[:is_active].presence || true
    end

    def charging_frequency
      properties[:charging_frequency].presence || 'monthly'
    end

    def functionalities_template
      { tracking_page: 'default' }
    end

    def operations_template
      { fullfilment: 'default',
        shipit_withdrawal: 'default',
        courier_withdrawal: 'default',
        on_demand_withdrawal_and_permanent_withdrawal: 'default' }
    end

    def configurations_template
      { users: 2, shipments: 1, apps_slots: 2 }
    end

    def apps_template
      { price_calculator: 'default', custom_notification: 'installable_app' }
    end

    def integrations
      { shopify: false, bootic: false, jumpseller: false, vtex: false, woocommerce: false, prestashop: false }
    end

    def agreement_date
      properties[:agreement_date].presence || Date.current
    end

    def expiration_date
      properties[:expiration_date].presence || Date.current + 1.month
    end
  end
end
