FactoryBot.define do
  factory :distribution_center do
    name { Faker::Name.name }
    cutting_hours { { 'ff' => 12.5, 'll' => 19, 'pp' => 13 } }
    association :cutting_hour
  end
end
