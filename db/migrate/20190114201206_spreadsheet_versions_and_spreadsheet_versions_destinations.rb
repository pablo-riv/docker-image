class SpreadsheetVersionsAndSpreadsheetVersionsDestinations < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :spreadsheet_versions, :json, null: true
    add_column :packages, :spreadsheet_versions_destinations, :json, null: true
  end
end
