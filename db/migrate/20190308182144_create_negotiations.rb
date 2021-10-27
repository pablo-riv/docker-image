class CreateNegotiations < ActiveRecord::Migration[5.0]
  def change
    create_table :negotiations do |t|
      t.belongs_to :company
      t.integer :kind
      t.float :percent, default: 0
      t.float :amount, default: 0
      t.json :recurrent, array: true, default: []

      t.timestamps
    end
  end
end
