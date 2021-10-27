class RenameIsReachableOnPackages < ActiveRecord::Migration[5.0]
  def change
    rename_column :packages, :is_recheabe, :is_reachable
  end
end
