class AddCourierStatusToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :courier_status, :string
  end
end
