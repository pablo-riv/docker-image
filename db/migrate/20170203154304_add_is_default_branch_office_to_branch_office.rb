class AddIsDefaultBranchOfficeToBranchOffice < ActiveRecord::Migration[5.0]
  def change
    add_column :branch_offices, :is_default, :boolean, default: false
  end
end
