class AddColumnAircallContactIdToCompanies < ActiveRecord::Migration[5.0]
  def up
    add_column :companies, :aircall_contact_id, :integer
    add_index :companies, [:aircall_contact_id], unique: true
  end

  def down
    remove_column :companies, :aircall_contact_id
    remove_index :companies, [:aircall_contact_id]
  end
end
