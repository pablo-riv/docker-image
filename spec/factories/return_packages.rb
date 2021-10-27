FactoryBot.define do
  factory :return_package do
    commune_id { FactoryBot.create(:commune).try(:id) }
    package_id { FactoryBot.create(:package).try(:id) }
    return_id { FactoryBot.create(:return).try(:id) }
    full_name { Faker::Name.name }
    phone { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    street { Faker::Address.street_name }
    zip_code { Faker::Address.zip_code }
    number { Faker::Address.building_number }
    complement { Faker::Address.secondary_address }
  end
end
