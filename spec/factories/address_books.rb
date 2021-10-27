require 'faker'
require 'pry'

FactoryBot.define do
  factory :address_book do
    after(:create, :build) do |address_book|
      addressable_id = FactoryBot.create(:address).id
      company = FactoryBot.create(:company, :default)
      address_book.update_attributes(addressable_id: addressable_id, address_id: company.address.id, company_id: company.id)
    end

    trait :origin do
      addressable_type { 'Origin' }
      full_name { Faker::Name.name }
      phone { Faker::PhoneNumber.subscriber_number(8) }
      email { Faker::Internet.email }
      default { false }
      address
    end

    trait :destiny do
      addressable_type { 'Destiny' }
      full_name { Faker::Name.name }
      phone { Faker::PhoneNumber.subscriber_number(8) }
      email { Faker::Internet.email }
      default { false }
      address
    end

    trait :return do
      addressable_type { 'Return' }
      full_name { Faker::Name.name }
      phone { Faker::PhoneNumber.subscriber_number(8) }
      email { Faker::Internet.email }
      default { false }
      address
    end
  end
end
