FactoryBot.define do
  factory :packages_pickup do
    association :package, factory: :package
    association :pickup, factory: :pickup
    deleted_at { nil }
    shipped { false }
  end
end
