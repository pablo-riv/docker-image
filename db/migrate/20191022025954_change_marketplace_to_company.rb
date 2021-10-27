class ChangeMarketplaceToCompany < ActiveRecord::Migration[5.0]
  def change
    rename_column :companies, :marketplaces, :sales_channel
  end
end
