class ChangeDownloadRelationship < ActiveRecord::Migration[5.0]
  def change
    remove_column :downloads, :account_id
    add_column :downloads, :company_id, :integer, index: true
    add_column :downloads, :is_archive, :boolean, default: false, index: true
  end
end
