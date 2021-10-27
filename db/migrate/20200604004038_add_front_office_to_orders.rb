class AddFrontOfficeToOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :orders, :front_office, :boolean, default: true
  end
end
