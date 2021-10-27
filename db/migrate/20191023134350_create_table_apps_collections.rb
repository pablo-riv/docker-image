class CreateTableAppsCollections < ActiveRecord::Migration[5.0]
  def self.up
    create_table :apps_collections do |t|
      t.belongs_to :app, index: true, foreign_key: true
      t.belongs_to :subscription, index: true, foreign_key: true
      t.boolean :active
      t.boolean :is_installed
      t.date :installation_date

      t.timestamps
    end
  end

  def self.down
    drop_table :apps_collections
  end
end
