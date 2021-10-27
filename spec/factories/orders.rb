FactoryBot.define do
  factory :order do
    state { 1 }
    items { 1 }
    kind { 'vtex' }
    reference { Faker::Code.ean }
    products { [{ sku_id: '1092', amount: 1 }] }
    sizes { { width: 1.0, height: 1.0, length: 1.0, weight: 4800.0, volumetric_weight: 4800.0, store: false, packing_id: nil, name: 'size for order 501449' } }
    insurance { { ticket_number: '501449', ticket_amount: 35_880, details: 'Vinos, Cervezas, Vinos y Licores, Categorías', extra: false } }
    platform { 'integration' }
    origin { { street: 'Apoquindo', number: '4499', complement: '1', commune_id: 308, full_name: 't1 t1', email: 't1@shipit.cl', phone: '12345464523', store: false, name: 'default' } }
    service { '' }
    seller { { status: '', name: '', id: '', reference_site: '' } }
    payable { false }
    courier { { delivery_time: 1, client: ['chilexpress', 'starken', 'bluexpress', 'motopartner', 'chileparcels', 'muvsmart', 'dhl', 'correoschile', 'shippify'].sample, entity: '', shipment_type: '', tracking: '', selected: false, zpl: '', epl: '', pdf: ''} }
    destiny {
      {
        street: 'Avenida Santa Maria',
        number: '0206',
        complement: '907',
        commune_id: Commune.all.sample.id,
        full_name: 'Renee Marlene Rivero Hurtado',
        email: Faker::Internet.email,
        phone: '+56945592086',
        store: false,
        destiny_id: nil,
        courier_branch_office_id: nil,
        kind: 'home_delivery',
        name: 'order destiny 501449'
      }
    }
  end
end