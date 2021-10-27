class AddDuemintReferenceToInvoice < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :duemint_reference, :string
  end
end
