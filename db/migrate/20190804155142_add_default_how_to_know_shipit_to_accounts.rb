class AddDefaultHowToKnowShipitToAccounts < ActiveRecord::Migration[5.0]
  def change
    change_column_default :accounts, :how_to_know_shipit, from: nil, to: {}
  end
end
