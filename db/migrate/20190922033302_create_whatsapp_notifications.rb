class CreateWhatsappNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :whatsapp_notifications do |t|
      t.integer :state
      t.json :text
      t.json :tags
      t.belongs_to :company, foreign_key: true, index: true

      t.timestamps
    end
  end
end
