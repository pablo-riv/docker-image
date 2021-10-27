class AddMonthlyRangeAndDefinitionToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :definition, :string
    add_column :companies, :package_monthly_range, :string
  end
end
