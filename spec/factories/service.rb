require 'faker'
FactoryBot.define do
  factory :service do
    name { Faker::Name.first_name }
  end
end
