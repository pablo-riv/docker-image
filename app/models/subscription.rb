class Subscription < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }

  # RELATIONS
  belongs_to :company
  belongs_to :plan
  has_many :apps_collections
  has_many :apps, through: :apps_collections

  accepts_nested_attributes_for :apps_collections

  # DELEGATORS
  delegate :name, allow_nil: false, to: :plan, prefix: 'plan'

  # CLASS METHODS
  def self.allowed_parameters
    [:subscription_id, :is_active, :plan_id, :agreement_date, :expiration_date, :charging_frequency, prices: prices, functionalities: allowed_functionalities, configurations: allowed_configurations, operations: allowed_operations, application_list: allowed_apps]
  end

  def self.prices
    %i[total_discount price_per_shipment floor_price]
  end

  def self.allowed_apps
    %i[price_calculator custom_notification np6_to_mail dashboard_advance_analytics zendesk_integration_client slack_integration_client custom_tracking_page whatsapp_notifications]
  end

  def self.allowed_functionalities
    %i[additional_shipping_insurance better_sla_algorithm tcc_integration_client tracking_page customer_service_centralized_in_shipit shipit_withdrawal courier_withdrawal]
  end

  def self.allowed_configurations
    %i[users shipments couriers shops_integrations apps_slots apps_slots_availables]
  end

  def self.allowed_operations
    %i[withdrawal_request_selecting_shipments_and_choosing_courier fullfilment shipit_withdrawal courier_withdrawal on_demand_withdrawal_and_permanent_withdrawal multiple_retirement_origins shipit_courier_label_printing manifest_printing personalized_customer_service customer_service_centralized_in_shipit]
  end

  def self.by_period(date)
    where(expiration_date: date)
  end
end
