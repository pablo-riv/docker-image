class CreateContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :contacts do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :role_name
      t.belongs_to :company, foreign_key: true

      t.timestamps
    end
  end
end
