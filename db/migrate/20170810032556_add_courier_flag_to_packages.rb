class AddCourierFlagToPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :without_courier, :boolean, default: false
  end
end
