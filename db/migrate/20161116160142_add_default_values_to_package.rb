class AddDefaultValuesToPackage < ActiveRecord::Migration[5.0]
  def change
    change_column_default :packages, :weight, from: nil, to: 1.0
    change_column_default :packages, :length, from: nil, to: 10
    change_column_default :packages, :width, from: nil, to: 10
    change_column_default :packages, :height, from: nil, to: 10
  end
end
