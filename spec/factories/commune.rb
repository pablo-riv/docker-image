require 'faker'

FactoryBot.define do
  factory :commune do
    name { Faker::Address.city }
    region_id { FactoryBot.create(:region).try(:id) }
    is_available { true }
    couriers_availables { { dhl: '', starken: 'LAS CONDES', muvsmart: 'LAS CONDES', chilexpress: 'LAS CONDES', motopartner: '', chileparcels: 'LAS CONDES', correoschile: '', shippify: 'LAS CONDES' } }
  end
end
