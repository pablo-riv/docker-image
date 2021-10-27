class AddReferenceBetweenOrderAndPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :order_id, :integer, index: true
    add_index :orders, :package_id
  end
end
