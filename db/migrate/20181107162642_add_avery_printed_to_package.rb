class AddAveryPrintedToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :avery_printed, :boolean, default: false
  end
end
