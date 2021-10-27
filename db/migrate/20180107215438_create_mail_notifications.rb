class CreateMailNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :mail_notifications do |t|
      t.integer :company_id, index: true
      t.json :text
      t.json :color
      t.json :tags
      t.boolean :tracking, default: true
      t.boolean :valid_format, default: false
      t.integer :state

      t.timestamps
    end
  end
end
