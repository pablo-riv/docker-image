class CreatePickups < ActiveRecord::Migration[5.0]
  def change
    create_table :pickups do |t|
      t.integer :provider
      t.integer :status
      t.integer :type_of_pickup
      t.boolean :archive, default: false
      t.json :schedule, default: { date: '', range_time: '', active: false }
      t.json :address, default:  { place: '', coords: { lat: 0, lng: 0 } }
      t.timestamps
    end

    create_table :packages_pickups do |t|
      t.belongs_to :pickup, class_name: 'pickup', foreign_key: 'pickup_id'
      t.belongs_to :package, class_name: 'package', foreign_key: 'package_id'
      t.boolean :shipped, default: false
    end

    remove_column :manifests, :name, :string
    remove_column :manifests, :courier, :string
    add_column :manifests, :pickup_id, :integer, index: true
  end
end
