FactoryBot.define do
  factory :whatsapp do
    state { 1 }
    sent { false }
    package { nil }
  end
end
