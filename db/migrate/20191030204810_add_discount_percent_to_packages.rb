class AddDiscountPercentToPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :discount_percent, :float
    add_column :packages, :discount_amount, :float
  end
end
