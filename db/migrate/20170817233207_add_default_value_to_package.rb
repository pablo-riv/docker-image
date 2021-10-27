class AddDefaultValueToPackage < ActiveRecord::Migration[5.0]
  def change
    change_column_default :packages, :without_courier, from: nil, to: false
    change_column_default :packages, :is_payable, from: nil, to: false
  end
end
