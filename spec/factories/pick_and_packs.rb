FactoryBot.define do
  factory :pick_and_pack do
    association :branch_office
    association :origin
    association :service
    provider { (0..7).to_a.sample }
    state { (0..1).to_a.sample }
    frequency { (0..2).to_a.sample }
    manifest { (0..1).to_a.sample }
    seller { 0 }
    labels { 0 }
  end
end
