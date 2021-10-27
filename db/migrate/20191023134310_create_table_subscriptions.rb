class CreateTableSubscriptions < ActiveRecord::Migration[5.0]
  def self.up
    create_table :subscriptions do |t|
      t.belongs_to :plan, index: true, foreign_key: true
      t.belongs_to :company, index: true, foreign_key: true
      t.string :charging_frequency, default: 'monthly'
      t.boolean :is_active, default: true
      t.date :agreement_date
      t.date :expiration_date
      t.json :prices
      t.json :application_list
      t.json :operations
      t.json :functionalities
      t.json :configurations

      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
