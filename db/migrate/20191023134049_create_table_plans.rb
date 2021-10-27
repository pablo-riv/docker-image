
class CreateTablePlans < ActiveRecord::Migration[5.0]
  def self.up
    create_table :plans do |t|
      t.string :name
      t.string :description
      t.boolean :is_active
      t.float :floor_price
      t.float :total_discount
      t.string :unit_price, default: 'uf'
    end
  end

  def self.down
    drop_table :plans
  end
end
