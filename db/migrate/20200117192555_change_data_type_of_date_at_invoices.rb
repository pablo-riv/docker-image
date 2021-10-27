class ChangeDataTypeOfDateAtInvoices < ActiveRecord::Migration[5.0]
  def change
    remove_column :invoices, :date
    add_column :invoices, :emit_date, :date

  end
end
