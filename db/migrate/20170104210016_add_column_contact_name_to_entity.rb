class AddColumnContactNameToEntity < ActiveRecord::Migration[5.0]
  def change
    add_column :entities, :contact_name, :string
  end
end
