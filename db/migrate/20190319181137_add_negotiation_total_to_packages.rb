class AddNegotiationTotalToPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :negotiation_total, :float, default: 0
  end
end
