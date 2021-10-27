class ChangeSpreadsheetLinkToBranchOffice < ActiveRecord::Migration[5.0]
  def change
    remove_column :packages, :google_sheet_link
    add_column :branch_offices, :google_sheet_link, :string
  end
end
