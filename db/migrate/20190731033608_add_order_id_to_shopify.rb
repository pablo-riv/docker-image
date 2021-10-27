class AddOrderIdToShopify < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :seller_order_id, :string, default: ''
  end
end
