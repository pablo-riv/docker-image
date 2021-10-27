class RenameIsReachableOnCommunes < ActiveRecord::Migration[5.0]
  def change
    rename_column :communes, :is_recheable, :is_reachable
  end
end
