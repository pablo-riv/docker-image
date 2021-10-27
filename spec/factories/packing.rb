require 'faker'

FactoryBot.define do
  factory :packing do
    name { Faker::FunnyName.name }
    sizes { {
      'length' => 10,
      'height' => 10,
      'width' => 10,
      'volumetric_weight' => 0.1,
    } }
    weight { 1 }
    company_id { Company.first.try(:id) || FactoryBot.build(:company, :default).id }
  end
end