class AddUniqueIndexToEntityCompany < ActiveRecord::Migration[5.0]
  def up
    add_column :entities, :reference_to_name, :string
    add_index :entities, :reference_to_name, unique: true
  end

  def down
    remove_column :entities, :reference_to_name, :string
    remove_index :entities, :reference_to_name
  end
end
