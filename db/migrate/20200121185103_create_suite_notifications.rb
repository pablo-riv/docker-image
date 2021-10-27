class CreateSuiteNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :suite_notifications do |t|
      t.string :title
      t.text :content
      t.integer :source
      t.integer :status
      t.boolean :readed, default: false
      t.boolean :is_archive, default: false, index: true
      t.references :company, index: true
      
      t.timestamps
    end
  end
end
