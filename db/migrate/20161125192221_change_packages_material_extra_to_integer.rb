class ChangePackagesMaterialExtraToInteger < ActiveRecord::Migration[5.0]
  def change
    remove_column :packages, :material_extra
    add_column :packages, :material_extra, :integer
  end
end
