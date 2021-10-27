FactoryBot.define do
  factory :invoice do
    company { nil }
    state { 1 }
    state_tracker { "" }
    currency { "MyString" }
    code { 1 }
    files { "" }
    amount { 1.5 }
    payment_method { "MyString" }
  end
end
