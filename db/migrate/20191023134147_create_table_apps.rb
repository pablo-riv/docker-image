class CreateTableApps < ActiveRecord::Migration[5.0]
  def self.up
    create_table :apps do |t|
      t.string :name
      t.string :description
      t.date :submitted_date
      t.date :last_updated
      t.string :requirements
      t.string :version
      t.float :monthly_charge
      t.float :variable_charge
      t.string :fee_unit

      t.timestamps
    end
  end

  def self.down
    drop_table :apps
  end
end
