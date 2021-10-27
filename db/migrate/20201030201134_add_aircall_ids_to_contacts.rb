class AddAircallIdsToContacts < ActiveRecord::Migration[5.0]
  def up
    add_column :contacts, :aircall_phone_id, :integer
    add_column :contacts, :aircall_email_id, :integer

    add_index :contacts, [:aircall_phone_id], unique: true
    add_index :contacts, [:aircall_email_id], unique: true
  end

  def down
    remove_column :contacts, :aircall_phone_id
    remove_column :contacts, :aircall_email_id

    remove_index :contacts, [:aircall_phone_id]
    remove_index :contacts, [:aircall_email_id]
  end
end
