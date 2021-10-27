class CreateBsaleWebhooks < ActiveRecord::Migration[5.0]
  def change
    create_table :bsale_webhooks do |t|
      t.integer :bsale_id
      t.string :order_url
      t.string :order_token
      t.string :bsale_order
      t.string :topic
      t.string :action
      t.integer :sent_at
      t.references :company, foreign_key: true

      t.timestamps
    end
  end
end
