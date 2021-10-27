class AddAttributeToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :expired_bill, :boolean, default: false
  end
end
