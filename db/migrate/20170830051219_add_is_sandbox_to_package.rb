class AddIsSandboxToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :is_sandbox, :boolean, default: false
  end
end
