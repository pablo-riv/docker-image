require 'faker'

FactoryBot.define do
  factory :product do
    name { Faker::Beer.name }
    description { Faker::Lorem.paragraph(2, true, 6) }
    sizes { {
      'length' => 10,
      'height' => 10,
      'width' => 10,
      'volumetric_weight' => 0.1,
    } }
    weight { 1 }
    sku { Faker::Code.nric }
    stock { 10 }
    price { 3200 }
    company_id { Company.first.try(:id) || FactoryBot.build(:company, :default).id }
  end
end