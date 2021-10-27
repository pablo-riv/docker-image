FactoryBot.define do
  factory :destiny do
    name { Faker::Name.first_name }
    association :address_book, factory: :address_book
  end
end
