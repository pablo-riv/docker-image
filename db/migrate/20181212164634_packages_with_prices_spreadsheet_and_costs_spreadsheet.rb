class PackagesWithPricesSpreadsheetAndCostsSpreadsheet < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :prices_spreadsheet, :string, null: true, limit: 256
    add_column :packages, :costs_spreadsheet, :string, null: true, limit: 256
  end
end
