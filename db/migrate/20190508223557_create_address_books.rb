class CreateAddressBooks < ActiveRecord::Migration[5.0]
  def change
    create_table :address_books do |t|
      t.references :addressable, polymorphic: true, index: true
      t.string :full_name
      t.string :phone
      t.string :email
      t.boolean :default
      t.belongs_to :address, foreign_key: true

      t.timestamps
    end
  end
end
