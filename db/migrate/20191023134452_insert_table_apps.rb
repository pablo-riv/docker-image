class InsertTableApps < ActiveRecord::Migration[5.0]
  def self.up
    App.create(id: 1, name: 'price_calculator', description: 'price_calculator', submitted_date: Date.current, last_updated: Date.current, requirements: '', version: 'v1', monthly_charge: 0.0, variable_charge: 0.0 , fee_unit: 'per unit')
    App.create(id: 2, name: 'custom_notification', description: 'custom_notification', submitted_date: Date.current, last_updated: Date.current, requirements: '', version: 'v1', monthly_charge: 0.0, variable_charge: 0.0 , fee_unit:'per unit')
    App.create(id: 3, name: 'np6_to_mail', description: 'np6_to_mail', submitted_date: Date.current, last_updated: Date.current, requirements: '', version: 'v1', monthly_charge: 0.0, variable_charge: 0.0 , fee_unit:'per month')
    App.create(id: 4, name: 'dashboard_advance_analytics', description: 'dashboard_advance_analytics', submitted_date: Date.current, last_updated: Date.current, requirements: '', version: 'v1', monthly_charge: 0.0, variable_charge: 0.0 , fee_unit:'per month')
    App.create(id: 5, name: 'zendesk_integration_client', description: 'zendesk_integration_client', submitted_date: Date.current, last_updated: Date.current, requirements: '', version: 'v1', monthly_charge: 0.0, variable_charge: 0.0 , fee_unit:'per ticket')
    App.create(id: 6, name: 'slack_integration_client', description: 'slack_integration_client', submitted_date: Date.current, last_updated: Date.current, requirements: '', version: 'v1', monthly_charge: 0.0, variable_charge: 0.0 , fee_unit:'per message')
    App.create(id: 7, name: 'custom_tracking_page', description: 'custom_tracking_page', submitted_date: Date.current, last_updated: Date.current, requirements: '', version: 'v1', monthly_charge: 0.0, variable_charge: 0.0 , fee_unit:'per shipment')
    App.create(id: 8, name: 'whatsapp_notifications', description: 'whatsapp_notifications', submitted_date: Date.current, last_updated: Date.current, requirements: '', version: 'v1', monthly_charge: 0.0, variable_charge: 0.0 , fee_unit: 'per message')
  end

  def self.down
    App.delete_all
  end
end
