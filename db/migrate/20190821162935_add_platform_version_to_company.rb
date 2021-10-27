class AddPlatformVersionToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :platform_version, :integer, default: 2
  end
end
