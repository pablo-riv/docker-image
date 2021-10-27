class CreateAddresses < ActiveRecord::Migration[5.0]
  def change
    create_table :addresses do |t|
      t.references :commune, foreign_key: true
      t.string :complement
      t.integer :number
      t.string :street
      t.json :coords, default: { latitude: 0.0, longitude: 0.0 }

      t.timestamps
    end
  end
end
