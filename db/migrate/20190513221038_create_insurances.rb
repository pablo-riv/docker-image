class CreateInsurances < ActiveRecord::Migration[5.0]
  def change
    create_table :insurances do |t|
      t.float :ticket_amount, default: 0.0
      t.string :ticket_number, default: ''
      t.string :name, default: ''
      t.float :extra_insurance, default: 0.0
      t.float :price, default: 0.0
      t.string :detail, default: ''
      t.belongs_to :company, index: true
      t.boolean :default, default: false
      t.boolean :archive, default: false

      t.timestamps
    end
  end
end
