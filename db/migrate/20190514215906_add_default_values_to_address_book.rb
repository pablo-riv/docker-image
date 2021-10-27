class AddDefaultValuesToAddressBook < ActiveRecord::Migration[5.0]
  def change
    change_column_default :address_books, :default, from: nil, to: false
  end
end
