class CreateCommunes < ActiveRecord::Migration[5.0]
  def change
    create_table :communes do |t|
      t.references :region, foreign_key: true
      t.string :name
      t.string :code
      t.boolean :is_starken
      t.boolean :is_chilexpress
      t.boolean :is_generic
      t.boolean :is_recheable

      t.timestamps
    end
  end
end
