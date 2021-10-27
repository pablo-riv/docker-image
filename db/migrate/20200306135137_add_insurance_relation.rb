class AddInsuranceRelation < ActiveRecord::Migration[5.0]
  def up
    change_column :orders, :insurance, :json, default: { ticket_amount: 0.0, active: false, extra: false, ticket_number: '', ticket_detail: '', price: 0.0 }
    remove_column :insurances, :name
    remove_column :insurances, :default
    remove_column :insurances, :extra_insurance
    add_column :insurances, :extra, :boolean, default: false 
    add_column :insurances, :package_id, :integer, index: true
    add_column :insurances, :active, :boolean, default: true
    add_index :insurances, :package_id
  end

  def down
    change_column :orders, :insurance, :json, default: { max_amount: 0.0, ticket_amount: 0.0, price: 0.0, active: false, extra: false, ticket_number: '' }
    add_column :insurances, :name, :string, default: ''
    add_column :insurances, :extra_insurance, :float, default: 0.0
    add_column :insurances, :default, :boolean, default: false
    remove_column :insurances, :package_id
    remove_columns :insurances, :extra
    remove_column :insurances, :active
  end
end
