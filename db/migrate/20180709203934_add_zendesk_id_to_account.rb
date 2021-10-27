class AddZendeskIdToAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :zendesk_id, :string
  end
end
