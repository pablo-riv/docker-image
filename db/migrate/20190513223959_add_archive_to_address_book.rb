class AddArchiveToAddressBook < ActiveRecord::Migration[5.0]
  def change
    add_column :address_books, :archive, :boolean, default: false
  end
end
