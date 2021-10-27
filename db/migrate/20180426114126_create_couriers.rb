class CreateCouriers < ActiveRecord::Migration[5.0]
  def change
    create_table :couriers do |t|
      t.string :name
      t.boolean :available_to_ship
      t.string :image_original_url
      t.string :image_square_url

      t.timestamps
    end

    say "Creating Courriers"
    Courier.create(name: 'DHL', available_to_ship: true, image_original_url: '', image_square_url: '')
    Courier.create(name: 'chilexpress', available_to_ship: true, image_original_url: '', image_square_url: '')
    Courier.create(name: 'starken', available_to_ship: true, image_original_url: '', image_square_url: '')
    Courier.create(name: 'correos_de_chile', available_to_ship: false, image_original_url: '', image_square_url: '')
    Courier.create(name: 'muvsmart', available_to_ship: false, image_original_url: '', image_square_url: '')
    Courier.create(name: 'chileparcels', available_to_ship: true, image_original_url: '', image_square_url: '')
    Courier.create(name: 'motopartner', available_to_ship: true, image_original_url: '', image_square_url: '')
    Courier.create(name: 'bluexpress', available_to_ship: true, image_original_url: '', image_square_url: '')
    Courier.create(name: 'shippify', available_to_ship: true, image_original_url: '', image_square_url: '')

  end
end
