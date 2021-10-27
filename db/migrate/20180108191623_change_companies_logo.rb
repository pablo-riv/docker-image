class ChangeCompaniesLogo < ActiveRecord::Migration[5.0]
  def change
    remove_column :entities, :logo, :string
    add_attachment :companies, :logo, :string
  end
end
