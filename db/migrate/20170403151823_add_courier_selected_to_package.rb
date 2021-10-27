class AddCourierSelectedToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :courier_selected, :boolean, default: false
  end
end
