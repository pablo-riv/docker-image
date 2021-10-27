class AddCouriersFlagToPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :apply_courier_discount, :boolean, default: true
  end
end
