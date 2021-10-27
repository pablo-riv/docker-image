class AddIndexToOrders < ActiveRecord::Migration[5.0]
  def change
    add_index :orders, :id
  end
end
