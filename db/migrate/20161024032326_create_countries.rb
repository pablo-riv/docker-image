class CreateCountries < ActiveRecord::Migration[5.0]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :postal_code
      t.string :phone_prefix
      t.attachment :flag_image

      t.timestamps
    end
  end
end
