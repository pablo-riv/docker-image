class CreateBeetrackRoutes < ActiveRecord::Migration[5.0]
  def change
    create_table :beetrack_routes do |t|
      t.integer :hero_id, null: false, index: true
      t.integer :route_id, null: false
      t.date :date, null: false, index: true
    end
  end
end
