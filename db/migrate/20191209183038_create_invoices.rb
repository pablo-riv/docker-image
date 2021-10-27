class CreateInvoices < ActiveRecord::Migration[5.0]
  def change
    create_table :invoices do |t|
      t.references :company, foreign_key: true, index: true
      t.integer :state, index: true, default: 0
      t.json :state_tracker, default: { expired: '', expired_soon: '', to_cancel: '', paid: '' }
      t.string :currency, default: ''
      t.integer :code, default: 33
      t.json :files, default: { pdf: '', xml: '', url: '' }
      t.float :amount, default: 0.0
      t.string :payment_method, default: ''

      t.timestamps
    end
  end
end
