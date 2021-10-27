class AddColumnsToWebhookNotifications < ActiveRecord::Migration[5.0]
  def change
    add_column :webhook_notifications, :tries_made, :integer
    add_column :webhook_notifications, :max_retries, :integer
    add_column :webhook_notifications, :code_response, :integer
  end
end
