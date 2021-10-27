class AddBugFiledToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :is_bug, :boolean
  end
end
