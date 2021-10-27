class UpdateDefaultValuesToCompanyFirstAndSecondOwnerIds < ActiveRecord::Migration[5.0]
  def change
    change_column_default :companies, :first_owner_id, from: 1, to: 14
    change_column_default :companies, :second_owner_id, from: 1, to: 14
  end
end
