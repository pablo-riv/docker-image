class CreateWebhookLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :webhook_logs do |t|
      t.json :response
      t.references :bsale_webhook, foreign_key: true

      t.timestamps
    end
  end
end
