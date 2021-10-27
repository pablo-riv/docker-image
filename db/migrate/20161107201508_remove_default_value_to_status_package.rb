class RemoveDefaultValueToStatusPackage < ActiveRecord::Migration[5.0]
  def change
    change_column_default :packages, :status, nil
  end
end
