class CreateAccomplishment < ActiveRecord::Migration[5.0]
  def self.up
    create_table :accomplishments do |t|
      t.boolean :client_preparation_accomplishment
      t.boolean :hero_pickup_accomplishment
      t.boolean :first_mile_accomplishment
      t.boolean :delivery_accomplishment
      t.boolean :total_accomplishment
      t.references :package, index: true

      t.timestamps
    end
    remove_column :packages, :first_mile_accomplishment
    remove_column :packages, :delivery_accomplishment
    remove_column :packages, :total_accomplishment
  end

  def self.down
    drop_table :accomplishments
    add_column :packages, :first_mile_accomplishment, :boolean
    add_column :packages, :delivery_accomplishment, :boolean
    add_column :packages, :total_accomplishment, :boolean
  end
end
