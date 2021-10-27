class AddFieldsToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :dni, :string
  end
end
