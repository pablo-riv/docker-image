class AddMarketplaceToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :marketplaces, :jsonb
  end
end
