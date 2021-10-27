class ChangeDefaultPlatformVersion < ActiveRecord::Migration[5.0]
  def change
    change_column_default :companies, :platform_version, from: 2, to: 3
  end
end
