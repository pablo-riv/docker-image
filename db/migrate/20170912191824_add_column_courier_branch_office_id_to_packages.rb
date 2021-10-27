class AddColumnCourierBranchOfficeIdToPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :courier_branch_office_id, :integer
  end
end
