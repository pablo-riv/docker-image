class AddCountForCompanySuiteSwitch < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :suite_disable_count, :integer, default: 0
    add_column :companies, :suite_enable_count, :integer, default: 0
  end
end
