class AddDestinyToPackage < ActiveRecord::Migration[5.0]
  def change
    change_column :packages, :shipping_type, :string
    add_column :packages, :destiny, :string
  end
end
