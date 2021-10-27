class CreatePrints < ActiveRecord::Migration[5.0]
  def change
    create_table :prints do |t|
      t.integer :company_id, index: true
      t.integer :quantity, default: 0
      t.timestamps
    end
  end
end
