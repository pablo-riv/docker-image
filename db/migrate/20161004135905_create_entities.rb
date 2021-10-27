class CreateEntities < ActiveRecord::Migration[5.0]
  def change
    create_table :entities do |t|
      t.string :name
      t.string :run
      t.string :website
      t.string :commercial_business
      t.string :phone
      t.string :logo
      t.text :about
      t.string :email_contact
      t.boolean :is_active, default: true
      t.string :address
      t.float :latitude
      t.float :longitude
      t.boolean :is_default, default: true
      t.actable

      t.timestamps
    end
  end
end
