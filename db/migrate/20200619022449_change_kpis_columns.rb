class ChangeKpisColumns < ActiveRecord::Migration[5.0]
  def up
    rename_column :kpis, :entity_id, :entity_last_checked_id
    add_column :kpis, :associated_courier, :string
  end

  def down
    rename_column :kpis, :entity_last_checked_id, :entity_id
    remove_column :kpis, :associated_courier, :string
  end
end
