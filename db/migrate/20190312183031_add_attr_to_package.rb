class AddAttrToPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :negotiation_kind, :string, default: 'amount'
    add_column :packages, :negotiation_amount, :float, default: 0
  end
end
