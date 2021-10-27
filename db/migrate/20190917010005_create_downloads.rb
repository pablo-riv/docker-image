class CreateDownloads < ActiveRecord::Migration[5.0]
  def change
    create_table :downloads do |t|
      t.integer :kind
      t.belongs_to :account, foreign_key: true, index: true
      t.string :link
      t.integer :status, default: 0
      t.boolean :downloaded, default: false

      t.timestamps
    end
  end
end
