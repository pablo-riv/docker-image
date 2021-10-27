require 'faker'
require 'pry'

FactoryBot.define do
  factory :address do
    street { Faker::Address.street_name }
    number { Faker::Address.building_number }
    coords { { lat: -39.819588, lng: -73.245209 } }
    complement { Faker::Address.secondary_address }
    commune_id { Commune.all.ids.sample || Commune.create!(FactoryBot.build(:commune).attributes).try(:id) }
    created_at { DateTime.current }
    updated_at { DateTime.current }
  end
end
