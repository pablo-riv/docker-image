class CreateOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :orders do |t|
      t.json :payment, default: { type: '', subtotal: 0.0, tax: 0.0, currency: 0.0, discounts: 0.0, total: 0.0, status: '', confirmed: false }
      t.json :source, default: { channel: '', ip: '', browser: '', language: '', location: '' }
      t.json :products, array: true, default: []
      t.json :seller, default: { status: '', name: '', id: '', reference_site: '' }
      t.json :gift_card, default: { from: '', amount: 0, total_amount: 0 }
      t.json :sizes, default: { width: 0.0, height: 0.0, length: 0.0, weight: 0.0, volumetric_wegiht: 0.0, store: false, packing_id: nil, name: '' }
      t.json :courier, default: { client: '', entity: '', shipment_type: '', tracking: '', selected: false, zpl: '', epl: '', pdf: '' }
      t.json :prices_versions, default: { spreadsheet_versions: [], spreadsheet_versions_destinations: { availables_from: {}, availables_to: {} } }
      t.json :prices, default: { total: 0.0, price: 0.0, cost: 0.0, insurance: 0.0, tax: 0.0, overcharge: 0.0 }
      t.json :insurance, default: { max_amount: 0.0, ticket_amount: 0.0, price: 0.0, active: false, extra: false, ticket_number: '' }
      t.json :state_track, default: { draft: '', confirmed: '', deliver: '', canceled: '', archived: ''}
      t.string :reference, default: ''
      t.integer :items, default: 0
      t.integer :kind
      t.integer :state
      t.integer :platform
      t.boolean :archive, default: false
      t.boolean :sandbox, default: false

      t.json :origin, default: { street: '', number: '', complement: '', commune_id: 0, full_name: '', email: '', phone: '', store: false, origin_id: nil, name: '' }
      t.json :destiny, default: { street: '', number: '', complement: '', commune_id: 0, full_name: '', email: '', phone: '', store: false, destiny_id: nil, courier_branch_office_id: nil, name: '' }

      t.timestamps
    end
  end
end
