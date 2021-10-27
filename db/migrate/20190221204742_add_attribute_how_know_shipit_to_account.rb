class AddAttributeHowKnowShipitToAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :how_to_know_shipit, :json
  end
end
