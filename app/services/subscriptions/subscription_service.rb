module Subscriptions
  class SubscriptionService
    FUNCTIONALITIES = %w[additional_shipping_insurance better_sla_algorithm tcc_integration_client].freeze
    OPERATIONS = %w[fullfilment shipit_withdrawal courier_withdrawal on_demand_withdrawal_and_permanent_withdrawal multiple_retirement_origins personalized_customer_service customer_service_centralized_in_shipit].freeze
    INTEGRATIONS = %w[shopify bootic jumpseller vtex woocommerce prestashop].freeze
    APPS = %w[price_calculator custom_notification np6_to_mail dashboard_advance_analytics zendesk_integration_client slack_integration_client custom_tracking_page whatsapp_notifications].freeze
    CONFIGURATIONS = %w[users shipments].freeze
    PLANS_TYPES = { 1 => StarterPlan, 2 => TakesOffPlan, 3 => AcceleratePlan, 4 => EnterprisePlan, 5 => CorporatePlan }.freeze

    attr_accessor :properties, :errors

    def initialize(company, properties)
      @company = company
      @properties = properties
      @errors = []
    end

    def generate(object = nil)
      plan_class = object.present? ? PLANS_TYPES[object[:plan_id]] : PLANS_TYPES[plan].new(@properties.merge(company_id: @company))
      return {} unless plan_class.present?

      Subscription.new(plan_class.template)
    end

    def plans_templates
      templates = []
      plans.each do |plan|
        template = generate(plan_id: plan.id)
        templates.push(plan_id: plan.id,
                       name: plan.name,
                       description: plan.description,
                       charging_frequency: template['charging_frequency'],
                       floor_price: plan.floor_price,
                       total_discount: plan.total_discount,
                       details: { apps: template['applications_list'],
                                  configurations: template['configurations'],
                                  operations: template['operations'] })
      end
      templates
    end

    private

    def definitions
      {
        company_id: @company,
        plan_id: plan,
        is_active: is_active?,
        agreement_date: agreement_date,
        expiration_date: expiration_date,
        charging_frequency: charging_frequency,
        prices: prices,
        functionalities: functionalities,
        operations: operations,
        configurations: configurations,
        applications: applications }
    end

    def is_active?
      properties[:is_active].presence || true
    end

    def plan
      properties[:plan_id].presence || 1
    end

    def prices
      properties[:prices].presence || { total_discount: total_discount, price_per_shipment: price_per_shipment, floor_price: floor_price }
    end

    def price_per_shipment
      properties[:prices][:price_per_shipment]
    end

    def floor_price
      properties[:prices][:floor_price]
    end

    def total_discount
      properties[:prices][:total_discount]
    end

    def functionalities
      properties[:functionalities]
    end

    def operations
      properties[:operations]
    end

    def configurations
      properties[:configurations]
    end

    def applications
      properties[:applications_list]
    end

    def status
      properties[:status]
    end

    def agreement_date
      properties[:agreement_date]
    end

    def expiration_date
      properties[:expiration_date]
    end

    def charging_frequency
      properties[:charging_frequency]
    end

    def plans
      Plan.where(is_active: true)
    end
  end
end
