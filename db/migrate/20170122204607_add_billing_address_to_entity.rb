class AddBillingAddressToEntity < ActiveRecord::Migration[5.0]
  def change
    add_column :entities, :billing_address_id, :integer
  end
end
