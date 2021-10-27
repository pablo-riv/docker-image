class AddingConstrainsToDb < ActiveRecord::Migration[5.0]
  def up
    # packages constrains
    add_column :packages, :reference_into_branch_office, :string, unique: true
    add_index :packages, [:reference_into_branch_office], unique: true
  end

  def down
    # packages constrains
    remove_column :packages, :reference_into_branch_office, :string
    remove_index :packages, :reference_into_branch_office
  end
end
