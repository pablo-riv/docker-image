class CreateSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :settings do |t|
      t.boolean :email_alert
      t.string :email_notification
      t.references :service, index: true
      t.references :company, foreign_key: true
      t.boolean :is_default_price, default: true
      t.string :default_courier, default: "cxp"
      
      t.timestamps
    end
  end
end
