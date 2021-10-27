class AddSuccessToWebhookNotifications < ActiveRecord::Migration[5.0]
  def change
    add_column :webhook_notifications, :success, :boolean
  end
end
