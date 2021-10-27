class AddCouriersAvailablesToCommune < ActiveRecord::Migration[5.0]
  def change
    add_column :communes, :couriers_availables, :jsonb
  end
end
