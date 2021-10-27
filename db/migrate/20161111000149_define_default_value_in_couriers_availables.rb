class DefineDefaultValueInCouriersAvailables < ActiveRecord::Migration[5.0]
  def change
    change_column :communes, :couriers_availables, :jsonb ,default: {}
  end
end
