class AddBranchOfficeIndexToOrigin < ActiveRecord::Migration[5.0]
  def change
    add_column :origins, :branch_office_id, :integer, index: true
  end
end
