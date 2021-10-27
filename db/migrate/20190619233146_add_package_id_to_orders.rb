class AddPackageIdToOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :orders, :package_id, :integer, index: true
  end
end
