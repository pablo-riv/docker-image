class AddDuemintAttributesToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :duemint_id, :integer
    add_column :companies, :duemint_url, :string
  end
end
