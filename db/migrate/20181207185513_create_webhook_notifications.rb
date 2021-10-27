class CreateWebhookNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :webhook_notifications do |t|
      t.string :model_sent
      t.integer :model_id
      t.string :url_sent
      t.string :kind_of_call

      t.timestamps
    end
  end
end
