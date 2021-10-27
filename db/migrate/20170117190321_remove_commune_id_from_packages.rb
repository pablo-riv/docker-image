class RemoveCommuneIdFromPackages < ActiveRecord::Migration[5.0]
  def change
    remove_column :packages, :commune_id, :integer
  end
end
