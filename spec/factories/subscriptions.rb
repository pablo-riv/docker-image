FactoryBot.define do
  factory :subscription do
    plan_id { 1 }
    agreement_date { Date.current }
    expiration_date { Date.current }
    prices { { total_discount: 4.0, price_per_shipment: 0, floor_price: 0.9 } }
    application_list { { price_calculator: 'default', custom_notification: 'installable_app' } }
    functionalities { { tracking_page: 'default'} }
    configurations { { users: 2, shipments: 1, apps_slots: 2 } }
    operations { { fullfilment: 'default',
                   shipit_withdrawal: 'default',
                   courier_withdrawal: 'default',
                   on_demand_withdrawal_and_permanent_withdrawal: 'default' } }
  end
end
