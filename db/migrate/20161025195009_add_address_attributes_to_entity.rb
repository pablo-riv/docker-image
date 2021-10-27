class AddAddressAttributesToEntity < ActiveRecord::Migration[5.0]
  def change
    add_reference :entities, :address, foreign_key: true
    remove_column :entities, :address 
    remove_column :entities, :latitude 
    remove_column :entities, :longitude
  end
end
