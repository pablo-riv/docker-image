class CreateDropOut < ActiveRecord::Migration[5.0]
  def change
    create_table :drop_outs do |t|
      t.boolean :deactivated, default: :true
      t.string :reason
      t.string :other_reason
      t.string :details
      t.references :account, foreign_key: true, index: true

      t.timestamps
    end
  end
end
