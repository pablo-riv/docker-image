class AddCourierDestinyIdToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :courier_destiny_id, :integer, index: true
  end
end
