namespace :courier do
  desc 'Add default values to Courier'
  task setup: :environment do
    couriers = [
      {name: "DHL", available_to_ship: true, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/dhl.png"},
      {name: "Chilexpress", available_to_ship: true, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/chilexpress.png"},
      {name: "Starken", available_to_ship: true, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/starken.png"},
      {name: "Correos Chile", available_to_ship: false, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/correos_de_chile.png"},
      {name: "Muv Smart", available_to_ship: true, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/muvsmart.png"},
      {name: "Chile Parcels", available_to_ship: true, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/chileparcels.png"},
      {name: "Moto Partner", available_to_ship: true, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/motopartner.png"},
      {name: "Bluexpress", available_to_ship: true, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/bluexpress.png"},
      {name: "Shippify", available_to_ship: true, image_original_url: "https://s3-us-west-2.amazonaws.com/couriers/shippify.png"}

    ]

    couriers.each do |courier|
      next if Courier.find_by name: courier[:name]
      Courier.create!(courier)
    end
  end

  desc 'Set generic courier and country to couriers'
  task add_generic_courier_and_country: :environment do
    puts '### Start to update couriers ###'
    begin
      country = Country.find_or_create_by!(name: 'Chile')
      Courier.all.each do |courier|
        generic_courier = GenericCourier.find_or_create_by!(name: courier.name, image_original_url: courier.image_original_url)
        courier.update(country: country, generic_courier: generic_courier)
      end
    rescue StandardError => e
      puts "Error al actualizar couriers desde opit\n Error: #{e.message}--".yellow
    end
    puts '### End to update couriers ###'
  end

  desc 'Create Moova'
  task create_moova: :environment do
    puts '### Start Moova Creation ###'
    ActiveRecord::Base.transaction do
      country = Country.find_or_create_by!(name: 'Chile')
      moova_logo_image_url = 'https://s3.us-west-2.amazonaws.com/couriers-shipit/moova.png'
      generic_courier =
        GenericCourier.find_or_create_by!(name: 'Moova',
                                          image_original_url: moova_logo_image_url)
      Courier.create!(name: generic_courier.name,
                      image_original_url: moova_logo_image_url,
                      country: country,
                      generic_courier: generic_courier,
                      available_to_ship: true,
                      description: 'https://moova.io/',
                      logo_url: moova_logo_image_url,
                      services: { 'next_day' => false, 'same_day' => true, 'saturday' => false, 'overnight' => false },
                      symbol: 'moova',
                      acronym: 'moova',
                      status_reader: 'webhook',
                      tracking_generator: 'task')
    end
    puts '### End to Moova Creation ###'
  end

  desc 'Create Chazki'
  task create_chazki: :environment do
    puts '### Start Chazki Creation ###'
    ActiveRecord::Base.transaction do
      country = Country.find_by!(name: 'Chile')
      chazki_logo_image_url = Rails.configuration.chazki[:icon]

      generic_courier = GenericCourier.find_or_initialize_by(name: 'Chazki').tap do |chazki|
        chazki.image_original_url = chazki_logo_image_url
        chazki.save
      end

      Courier.create!(name: generic_courier.name,
                      image_original_url: chazki_logo_image_url,
                      country: country,
                      generic_courier: generic_courier,
                      available_to_ship: true,
                      description: 'https://chazki.com/',
                      logo_url: chazki_logo_image_url,
                      services: { 'next_day' => false, 'same_day' => true, 'saturday' => false, 'overnight' => false },
                      symbol: 'chazki',
                      acronym: 'chazki',
                      status_reader: 'webhook',
                      tracking_generator: 'task')
    end
    puts '### End to Chazki Creation ###'
  end

  desc 'Create Spread'
  task create_spread: :environment do
    puts '### Start Spread Creation ###'
    ActiveRecord::Base.transaction do
      country  = Country.find_or_create_by!(name: 'Chile')
      logo_url = Rails.configuration.spread[:icon]

      services = {
        'next_day' => true,
        'same_day' => false,
        'saturday' => false,
        'overnight' => false
      }

      generic_courier = GenericCourier.find_or_initialize_by(name: 'Spread').tap do |spread|
        spread.image_original_url = logo_url
        spread.save!
      end

      Courier.create!(name: generic_courier.name,
                      image_original_url: logo_url,
                      country: country,
                      generic_courier: generic_courier,
                      available_to_ship: true,
                      description: 'https://spread.cl/',
                      logo_url: logo_url,
                      services: services,
                      symbol: generic_courier.name.downcase,
                      acronym: generic_courier.name.downcase,
                      status_reader: 'webhook',
                      tracking_generator: 'task')
    end
    puts '### End to Spread Creation ###'
  end

  desc 'Create MuvSmart MX'
  task create_muvsmart_mx: :environment do
    puts '### Start MuvSmart MX Creation ###'
    ActiveRecord::Base.transaction do
      country  = Country.find_by!(name: ['México', 'Mexico'])
      logo_url = Rails.configuration.muvsmart_mx[:icon]

      services = {
        'next_day' => false,
        'same_day' => true,
        'saturday' => false,
        'overnight' => false
      }

      generic_courier = GenericCourier.find_by(name: 'Muvsmart')

      courier = Courier.find_by(symbol: 'muvsmart_mx')
      unless courier.present?
        courier = Courier.create!(name: 'Muvsmart_Mx',
                                  image_original_url: logo_url,
                                  country: country,
                                  generic_courier: generic_courier,
                                  available_to_ship: true,
                                  description: 'https://99minutos.com/',
                                  logo_url: logo_url,
                                  services: services,
                                  symbol: 'muvsmart_mx',
                                  acronym: 'muvsmart_mx',
                                  status_reader: 'webhook',
                                  tracking_generator: 'task')
      end

      courier_alias = courier.courier_aliases.find_by(name: 'muv_smart_mx')
      unless courier_alias.present?
        courier_alias = courier.courier_aliases.create(name: 'muv_smart_mx')
        puts "Courier Alias created #{courier_alias.name}"
      end
    end
    puts '### End to MuvSmart MX Creation ###'
  end
end
