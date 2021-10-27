class AddColumnRequesterTypeToSupports < ActiveRecord::Migration[5.0]
  def change
    add_column :supports, :requester_type, :integer, default: 6
  end
end
