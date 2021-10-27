FactoryBot.define do
  factory :whatsapp_notification do
    state { 1 }
    text { "" }
    tags { "" }
    company { nil }
  end
end
