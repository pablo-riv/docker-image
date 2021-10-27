class CreateWhatsapps < ActiveRecord::Migration[5.0]
  def change
    create_table :whatsapps do |t|
      t.integer :state
      t.boolean :sent
      t.belongs_to :package, foreign_key: true, index: true

      t.timestamps
    end
  end
end
