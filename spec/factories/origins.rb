FactoryBot.define do
  factory :origin do
    name { Faker::Name.first_name }
    association :address_book, :origin
  end
end
