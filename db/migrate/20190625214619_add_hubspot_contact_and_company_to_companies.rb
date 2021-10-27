class AddHubspotContactAndCompanyToCompanies < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :hubspot_company_id, :string, index: true, default: ''
    add_column :companies, :hubspot_contact_id, :string, index: true, default: ''
  end
end
