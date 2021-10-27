#Destroy all
#Service.destroy_all
#Commune.destroy_all
#Region.destroy_all
#Company.destroy_all


puts 'Creating services'
Service.create(name: 'opit')
Service.create(name: 'fullit')
Service.create(name: 'pp')
Service.create(name: 'fulfillment')
Service.create(name: 'sd')
Service.create(name: 'notification')
Service.create(name: 'printers')
Service.create(name: 'analytics')
Service.create(name: 'automatizations')
puts 'Creating regions'
Region.create(name: 'Arica y Parinacota', number: '15', roman_numeral: 'XV')
Region.create(name: 'Tarapaca', number: '1', roman_numeral: 'I')
Region.create(name: 'Antofagasta', number: '2', roman_numeral: 'II')
Region.create(name: 'Atacama', number: '3', roman_numeral: 'III')
Region.create(name: 'Coquimbo', number: '4', roman_numeral: 'IV')
Region.create(name: 'Valparaiso', number: '5', roman_numeral: 'V')
Region.create(name: 'Metropolitana', number: '13', roman_numeral: 'RM')
Region.create(name: "O'Higgins", number: '6', roman_numeral: 'VI')
Region.create(name: 'Maule', number: '7', roman_numeral: 'VII')
Region.create(name: 'Biobio', number: '8', roman_numeral: 'VIII')
Region.create(name: 'Araucania', number: '9', roman_numeral: 'IX')
Region.create(name: 'Los Rios', number: '14', roman_numeral: 'XIV')
Region.create(name: 'Los Lagos', number: '10', roman_numeral: 'X')
Region.create(name: 'Aysen', number: '11', roman_numeral: 'XI')
Region.create(name: 'Magallanes', number: '12', roman_numeral: 'XII')
puts 'Creating communes'
data = JSON.parse(File.read("#{Rails.root}/lib/data/communes.json"))
data['regions'].each do |json_region|
  region = Region.find_by(name: json_region['name'])
  next unless region.persisted?
  json_region['communes'].each do |commune|
    ca_json = {"dhl"=>commune['name'], "starken"=>commune['name'], "chilexpress"=>commune['name'], "correoschile"=>commune['name']}
    region.communes.create!(name: commune['name'],code: commune['id'],is_reachable: true,is_generic: true, couriers_availables: ca_json)
  end
end

communes_id = Commune.all.pluck(:id)

Address.all.each do |addresses|
  addresses.update_columns(commune_id: communes_id.sample)
end

puts 'Creating Shipit company and account'
company = Company.new(name: 'Shipit', sales_channel: { names: [], categories: [] })
company.save(validate: false)
company_account = company.accounts.new(email: 'staff@shipit.cl',
                                       password: 'password',
                                       password_confirmation: 'password',
                                       person: Person.create!(first_name: 'staff', last_name: 'shipit'))
company.generate_relation
company.acting_as.generate_relation
company_account.save(validate: false)
puts 'Saving shipit company and account'
company.acting_as.address.update_columns(street: 'Asturias', number: '103', complement: 'Casa D', commune_id: Commune.where("name like '%LAS CONDES%'").first.id)
puts 'company address are updated'
company.default_branch_office.acting_as.generate_relation
company.default_branch_office.acting_as.address.update_columns(street: 'Asturias', number: '103', complement: 'Casa D', commune_id: Commune.where("name like '%LAS CONDES%'").first.id)
puts 'company and branch_office address are updated'
