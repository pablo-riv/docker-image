require 'faker'
FactoryBot.define do
  factory :hero do
    sequence(:email) { |n| Faker::Internet.email }
    before(:create) do |hero|
      person = Person.create(first_name: Faker::Name.first_name,
                             last_name: Faker::Name.last_name)
      hero.person_id = person.id
    end
  end
end