class SetIsArchiveToPackages < ActiveRecord::Migration[5.0]
  def change
    change_column_default :packages, :is_archive, false
  end
end