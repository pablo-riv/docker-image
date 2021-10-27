class AddLastZendeskUpdateToAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :last_update_zendesk_date, :datetime
  end
end
