class AddMonthToInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :month, :integer
    add_index :invoices, :month
  end
end
