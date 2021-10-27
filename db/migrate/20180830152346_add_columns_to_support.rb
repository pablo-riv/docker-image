class AddColumnsToSupport < ActiveRecord::Migration[5.0]
  def change
    add_column :supports, :last_response_name, :string
    add_column :supports, :last_response_date, :datetime
  end
end
