class AddGetToParkingToBranchOffice < ActiveRecord::Migration[5.0]
  def change
    add_column :branch_offices, :get_to_parking, :text
  end
end
