class AddColumnsToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :sku, :string
    add_column :products, :stock, :integer, default: 0
    add_column :products, :price, :float, default: 0.0
  end
end
