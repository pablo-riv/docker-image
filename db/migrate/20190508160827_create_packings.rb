class CreatePackings < ActiveRecord::Migration[5.0]
  def change
    create_table :packings do |t|
      t.string :name
      t.belongs_to :company
      t.json :sizes, default: { width: 0.0, height: 0.0, length: 0.0, volumetric_weight: 0.0 }
      t.float :weight
      t.boolean :default, default: false
      t.boolean :archive, default: false

      t.timestamps
    end
  end
end
