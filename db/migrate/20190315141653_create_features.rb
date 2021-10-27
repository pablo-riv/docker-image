class CreateFeatures < ActiveRecord::Migration[5.0]
  def change
    create_table :features do |t|
      t.string :name
      t.integer :price, defaut: 0

      t.timestamps
    end
  end
end
