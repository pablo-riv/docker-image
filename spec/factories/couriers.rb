FactoryBot.define do
  factory :courier do
    name { Faker::Name.name }
    available_to_ship { false }
    image_original_url { 'MyString' }
    image_square_url { 'MyString' }
  end
end
