FactoryBot.define do
  factory :webhook_log do
    response { "" }
    bsale_webhook { nil }
  end
end
