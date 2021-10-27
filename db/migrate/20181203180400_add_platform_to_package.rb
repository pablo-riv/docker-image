class AddPlatformToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :platform, :integer
  end
end
