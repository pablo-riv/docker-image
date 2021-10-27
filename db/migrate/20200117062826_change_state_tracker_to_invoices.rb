class ChangeStateTrackerToInvoices < ActiveRecord::Migration[5.0]
  def change
    change_column_default :invoices, :state_tracker, from: { expired: '',
                                                             expired_soon: '',
                                                             to_cancel: '',
                                                             paid: '' },
                                                     to: { created: '',
                                                           expired_soon: '',
                                                           expired: '',
                                                           to_cancel: '',
                                                           paid: '' }
    add_column :invoices, :paid_amount, :float, default: 0.0
    add_column :invoices, :paid_date, :date
    add_column :invoices, :taxes, :float, default: 0.0
    add_column :invoices, :net, :float, default: 0.0
    add_column :invoices, :notes, :string, default: ''
    add_column :invoices, :gloss, :string, default: ''
    add_column :invoices, :due_date, :date
    add_column :invoices, :number, :bigint
    rename_column :invoices, :month, :date
  end
end
