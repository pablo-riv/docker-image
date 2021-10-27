class AddCascadeToPackagesPickups < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :packages_pickups, :packages
    remove_foreign_key :packages_pickups, :pickups
    add_foreign_key :packages_pickups, :pickups, on_delete: :cascade
    add_foreign_key :packages_pickups, :packages, on_delete: :cascade
  end
end
