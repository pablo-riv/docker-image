class ChangeColumnMongoOrderIdForString < ActiveRecord::Migration[5.0]
  def change
    change_column :packages, :mongo_order_id, :string
  end
end
