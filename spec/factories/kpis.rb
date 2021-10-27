require 'pry'

FactoryBot.define do
  factory :kpi do
    trait :default_sla do
      kpiable_type { 'Company' }
      kpiable_id { Company&.ids&.sample || FactoryBot.create(:company, :default).id }
      kind { :sla }
      aggregation { 'day' }
      associated_date { Date.current.beginning_of_day }
      associated_courier { 'shipit' }
      value { rand(1..100).to_f }
      entity_type { 'Package' }
      entity_last_checked_id { Package&.ids&.sample || FactoryBot.create(:package).id }
      entity_accumulated_quantity { rand(1..1000) }
    end
  end
end
