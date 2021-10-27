class AddAttrToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :business_name, :string, default: ''
    add_column :companies, :business_turn, :string, default: ''
    add_column :companies, :bill_address, :string, default: ''
    add_column :companies, :bill_email, :string, default: ''
    add_column :companies, :bill_phone, :string, default: ''
  end
end
