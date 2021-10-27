class AddServiceToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :service, :integer, default: 0
  end
end
