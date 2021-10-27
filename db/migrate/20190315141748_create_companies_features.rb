class CreateCompaniesFeatures < ActiveRecord::Migration[5.0]
  def change
    create_table :companies_features do |t|
      t.belongs_to :company, index: true
      t.belongs_to :feature, index: true
      t.boolean :active, index: true, default: true
      t.integer :price

      t.timestamps
    end
  end
end
