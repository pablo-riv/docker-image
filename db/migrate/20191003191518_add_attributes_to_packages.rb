class AddAttributesToPackages < ActiveRecord::Migration[5.0]
  def change
    add_column :packages, :printed_date, :date
  end
end
