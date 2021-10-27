class RollbackDefaultPlatformVersion < ActiveRecord::Migration[5.0]
  def change
    change_column_default :companies, :platform_version, from: 3, to: 2
  end
end
