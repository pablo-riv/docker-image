FactoryBot.define do
  factory :bsale_webhook do
    bsale_id { 1 }
    order_url { "/v2/token/checkout/b52982dd26435170d06a60d63c493350919e88d6.json" }
    order_token { "b52982dd26435170d06a60d63c493350919e88d6" }
    bsale_order { "b52982dd26435170d06a60d63c493350919e88d6" }
    topic { "webOrder" }
    action { "post" }
    sent_at { 1565365016 }
    company { Account.find_by(email: 'staff@shipit.cl').current_company }
  end
end
