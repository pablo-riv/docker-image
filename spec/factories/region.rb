require 'faker'
FactoryBot.define do
  factory :region do
    name { Faker::Address.city }
  end
end
