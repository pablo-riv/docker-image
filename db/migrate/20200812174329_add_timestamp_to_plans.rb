class AddTimestampToPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :plans, :created_at, :datetime, default: DateTime.current
    add_column :plans, :updated_at, :datetime, default: DateTime.current
  end
end
