namespace :region do
  desc 'Assign country to regions'
  task assign_country_to_regions: :environment do
    puts '### Start to create couriers ###'
    country = Country.find_or_create_by(name: 'Chile')
    Region.update_all(country_id: country.id)
    puts '### End to create disabled couriers ###'
  end
end
