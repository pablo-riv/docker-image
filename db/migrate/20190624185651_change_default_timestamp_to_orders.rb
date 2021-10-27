class ChangeDefaultTimestampToOrders < ActiveRecord::Migration[5.0]
  def change
    change_column_null :orders, :created_at, true
    change_column_null :orders, :updated_at, true
  end
end
