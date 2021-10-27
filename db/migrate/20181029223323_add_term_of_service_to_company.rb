class AddTermOfServiceToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :term_of_service, :boolean, default: false
    add_column :companies, :know_size_restriction, :boolean, default: false
    add_column :companies, :know_base_charge, :boolean, default: false
  end
end
