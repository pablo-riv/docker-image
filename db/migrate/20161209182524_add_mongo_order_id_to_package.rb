class AddMongoOrderIdToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :mongo_order_id, :integer
  end
end
