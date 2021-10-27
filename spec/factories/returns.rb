FactoryBot.define do
  factory :return do
    name { Faker::Name.first_name }
    address_book { FactoryBot.create(:address_book, :return) }
  end
end
