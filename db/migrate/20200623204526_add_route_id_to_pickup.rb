class AddRouteIdToPickup < ActiveRecord::Migration[5.0]
  def change
    add_column :pickups, :route, :string, null: true, index: true
  end
end
