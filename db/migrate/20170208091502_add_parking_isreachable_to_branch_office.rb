class AddParkingIsreachableToBranchOffice < ActiveRecord::Migration[5.0]
  def change
    add_column :branch_offices, :parking_isreachable, :string
  end
end
