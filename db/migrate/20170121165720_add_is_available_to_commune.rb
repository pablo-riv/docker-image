class AddIsAvailableToCommune < ActiveRecord::Migration[5.0]
  def change
    add_column :communes, :is_available, :boolean, default: false
  end
end
