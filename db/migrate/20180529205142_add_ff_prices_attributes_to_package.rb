class AddFfPricesAttributesToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :ff_courier_for_client, :string
    add_column :packages, :ff_courier_for_entity, :string
    add_column :packages, :ff_shipping_price, :float
    add_column :packages, :ff_shipping_cost, :float
    add_column :packages, :ff_delivery_time, :float
    add_column :packages, :ff_width, :float
    add_column :packages, :ff_height, :float
    add_column :packages, :ff_items_count, :float
    add_column :packages, :ff_weight, :float
  end
end
