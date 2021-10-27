class AddDefaultValuesToPerson < ActiveRecord::Migration[5.0]
  def change
    change_column_default :people, :first_name, ''
    change_column_default :people, :last_name, ''
  end
end
