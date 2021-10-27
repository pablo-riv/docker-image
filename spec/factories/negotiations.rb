FactoryBot.define do
  factory :negotiation do
    company_id { FactoryBot.create(:company, :default).id }
    kind 1
    percent 1.5
    amount 1.5
    recurrent ""
  end
end
