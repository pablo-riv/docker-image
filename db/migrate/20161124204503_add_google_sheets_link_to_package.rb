class AddGoogleSheetsLinkToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :google_sheet_link, :string
  end
end
