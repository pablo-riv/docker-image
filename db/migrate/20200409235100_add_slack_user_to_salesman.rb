class AddSlackUserToSalesman < ActiveRecord::Migration[5.0]
  def change
    add_column :salesmen, :slack_id, :string
  end
end
