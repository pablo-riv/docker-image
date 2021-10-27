FactoryBot.define do
  factory :location do
    association :area
    association :hero
  end
end