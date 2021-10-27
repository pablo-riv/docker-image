require 'faker'
require 'pry'

FactoryBot.define do
  factory :package do
    branch_office_id { Company.first.default_branch_office.id }
    pickup_id { 1 }
    full_name { Faker::Name.name }
    email { Faker::Internet.email }
    cellphone { Faker::PhoneNumber.phone_number }
    reference { Faker::Code.ean }
    length { 10 }
    height { 10 }
    width { 10 }
    weight { 1 }
    approx_size { ['Pequeño (10x10x10cm)', 'Mediano (30x30x30cm)', 'Grande (50x50x50cm)', 'Muy Grande (>60x60x60cm)'].sample }
    volume_price { 1.0 }
    is_payable { [false].sample }
    is_fragile { [true, false].sample }
    is_wrapper_paper { [true, false].sample }
    is_reachable { [true, false].sample }
    is_printed { [true, false].sample }
    is_paid_shipit { [true, false].sample }
    is_returned { [true, false].sample }
    is_available { [true, false].sample }
    is_archive { [true, false].sample }
    is_exception { [true, false].sample }
    is_mail_to_receiver { [true, false].sample }
    courier_for_entity { ['starken', 'chilexpress'].sample }
    courier_type { nil }
    courier_for_client { ['chilexpress', 'starken', 'bluexpress', 'motopartner', 'chileparcels', 'muvsmart', 'dhl', 'correoschile', 'shippify'].sample }
    comments { '' }
    reason { '' }
    serial_number { nil }
    items_count { rand(1..20) }
    product_type { nil }
    shipping_price { 1000 }
    total_price { 1000 }
    shipit_code { nil }
    shipping_cost { 1000 }
    shipping_type { 'Normal' }
    trello_item { '' }
    parent_ot { nil }
    has_ot { true }
    box_type { nil }
    packing { ['Sin Empaque', 'Papel Kraft'].sample }
    sell_type { nil }
    sku_supplier { 'No se ocupa' }
    supplier_name { 'No se ocupa' }
    craftman_state { nil }
    voucher_price { 1000 }
    pickup_distance { 1000 }
    kind_of_order { 'No se ocupa' }
    created_at { Time.now }
    updated_at { Time.now }
    status { [0,1,2,3,4,5].sample }
    inventory_activity { nil }
    destiny { ['Domicilio'].sample }
    mongo_order_id { nil }
    mongo_order_seller { ['dafiti', 'bootic', nil, nil, nil, 'woocommerce', 'prestashop', 'shopify'].sample }
    material_extra { 0 }
    # is_courier_printed true
    # v2 true
    # shipit_ticket_url { '' }
    courier_status { ['Ejemplo Entregado','Ejemplo Fallido'].sample }


    after(:build) do |package|
      package.address ||= FactoryBot.build(:address, package: package)
    end
  end
end
