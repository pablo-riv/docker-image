class CreateReturns < ActiveRecord::Migration[5.0]
  def change
    create_table :returns do |t|
      t.string :name

      t.timestamps
    end
  end
end
