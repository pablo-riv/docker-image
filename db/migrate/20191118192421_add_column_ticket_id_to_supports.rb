class AddColumnTicketIdToSupports < ActiveRecord::Migration[5.0]
  def change
    add_column :supports, :ticket_id, :integer
  end
end
