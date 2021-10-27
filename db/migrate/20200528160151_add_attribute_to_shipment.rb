class AddAttributeToShipment < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :front_office, :boolean, default: true
  end
end
