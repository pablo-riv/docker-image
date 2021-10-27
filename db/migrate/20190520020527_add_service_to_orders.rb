class AddServiceToOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :orders, :service, :integer, default: 0
    add_column :orders, :payable, :boolean, default: false
  end
end
