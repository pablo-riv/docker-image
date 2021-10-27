class AddPaymentDateToPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :payment_date, :date
  end
end
