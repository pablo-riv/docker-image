class CreateKpis < ActiveRecord::Migration[5.0]
  def change
    create_table :kpis do |t|
      t.references :kpiable, polymorphic: true, index: true
      t.integer :kind
      t.integer :aggregation, default: 0
      t.float :value, default: 0.0
      t.datetime :associated_date
      t.string :entity_type
      t.integer :entity_id
      t.integer :entity_accumulated_quantity

      t.timestamps
    end
  end
end
