require 'faker'

FactoryBot.define do
  factory :drop_out do
    reason { Faker::String.random }
    details { Faker::String.random }
  end
end
