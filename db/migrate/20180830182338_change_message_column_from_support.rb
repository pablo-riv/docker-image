class ChangeMessageColumnFromSupport < ActiveRecord::Migration[5.0]
  def change
    remove_column :supports, :messages, :string
    add_column :supports, :messages, :jsonb, array: true, default: []
  end
end
