module Subscriptions
  class StarterPlan
    attr_accessor :properties, :errors

    def self.template
      new(functionalities: nil,
          prirces: nil,
          operations: nil,
          configurations: nil,
          applications: nil,
          charging_frequency: nil).template
    end

    def initialize(properties = nil)
      @properties = properties
      @errors = []
    end

    def template
      { company_id: properties[:company_id],
        plan_id: 1,
        is_active: is_active?,
        agreement_date: agreement_date,
        expiration_date: expiration_date,
        charging_frequency: charging_frequency,
        prices: prices,
        operations: operations,
        functionalities: functionalities,
        configurations: configurations,
        application_list: applications,
        integrations: integrations }
    end

    def company
      properties[:company_id].presence || nil
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
      return 0.0 unless properties[:prices].present?

      properties[:prices][:floor_price].presence || 0.0
    end

    def total_discount
      return 0.0 unless properties[:prices].present?

      properties[:prices][:total_discount].presence || 0.0
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

    def functionalities_template
      { tracking_page: 'default' }
    end

    def operations_template
      {}
    end

    def configurations_template
      { users: 1, shipments: 0, couriers: 1, shops_integrations: 1, apps_slots: 0 }
    end

    def apps_template
      { price_calculator: 'default' }
    end

    def is_active?
      properties[:is_active].presence || true
    end

    def charging_frequency
      properties[:charging_frequency].presence || 'monthly'
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
