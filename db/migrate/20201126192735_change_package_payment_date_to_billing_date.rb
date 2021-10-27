class ChangePackagePaymentDateToBillingDate < ActiveRecord::Migration[5.0]
  def change
    rename_column :packages, :payment_date, :billing_date
  end
end
