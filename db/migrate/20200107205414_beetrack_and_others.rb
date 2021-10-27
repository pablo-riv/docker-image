class BeetrackAndOthers < ActiveRecord::Migration[5.0]
  def change
    # Unused, replaced by prices_spreadsheets
    remove_column :packages, :prices_spreadsheet
    
    # Unused, replaced by costs_spreadsheets
    remove_column :packages, :costs_spreadsheet
    
    # New columns that will be used in Beetrack
    add_column :packages, :processed_by_beetrack, :boolean, :default => false, :null => true, index: true
    add_column :packages, :deleted_in_beetrack, :boolean, :default => false, :null => true, index: true
  end
end
