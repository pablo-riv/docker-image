FactoryBot.define do
  factory :origin_package do
    commune_id { FactoryBot.create(:commune).try(:id) }
    package_id { FactoryBot.create(:package).try(:id) }
    origin_id { FactoryBot.create(:origin).try(:id) }
    full_name { Faker::Name.name }
    phone { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    street { Faker::Address.street_name }
    zip_code { Faker::Address.zip_code }
    number { Faker::Address.building_number }
    complement { Faker::Address.secondary_address }
  end
end
