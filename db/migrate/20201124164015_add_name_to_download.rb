class AddNameToDownload < ActiveRecord::Migration[5.0]
  def change
    add_column :downloads, :name, :string, default: ''
    add_column :downloads, :error, :string, default: nil
  end
end
