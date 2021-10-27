class AddDefaultCompanyAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :default, :boolean, default: false
    add_index :accounts, :default
  end
end
