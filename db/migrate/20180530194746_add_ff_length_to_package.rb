class AddFfLengthToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :ff_length, :float
  end
end
