class AddColumnShowClientToSupports < ActiveRecord::Migration[5.0]
  def change
    add_column :supports, :show_client, :boolean, default: true
  end
end
