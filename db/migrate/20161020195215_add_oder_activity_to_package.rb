class AddOderActivityToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :inventory_activity, :json
  end
end
