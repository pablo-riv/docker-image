FactoryBot.define do
  factory :plan do
    name { '' }
    description { '' }
    is_active { true }
    floor_price { 0.0 }
    total_discount { 0.0 }
    unit_price { 'uf' }
  end
end
