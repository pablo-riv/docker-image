FactoryBot.define do
  factory :cutting_hour do
    pick_and_pack_service { '11:00:00-03' }
    fulfillment_service { '11:00:00-03' }
    labelling_service { '19:00:00-03' }
  end
end
