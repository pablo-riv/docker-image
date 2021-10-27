require 'pry'
require 'rails_helper'

describe Coverages::Courier do
  context 'courier coverage service' do
    let(:coverages) {
      { data: 
        [{
          'courier': {
              'id': 1,
              'name': 'Chilexpress'
          },
          'courier_service_type': {
              'id': 4,
              'name': 'SSD COURIER 1'
          },
          'couriers_branch_office': {
              'id': 787,
              'name': 'Arica Panamericana Norte'
          },
          'delivery_type': {
              'id': 1,
              'name': 'Pickup'
          },
          'destiny': {
              'commune_id': 2,
              'commune_name': 'CAMARONES',
              'commune_name_for_courier': nil
          },
          'estimated_delivery_days': 1,
          'id': 10,
          'origin': {
              'commune_name': 'ARICA',
              'commune_name_for_courier': 'ARICA TEST',
              'comune_id': 1
          },
          'payment_type': {
              'id': 2,
              'name': 'Efectivo'
          },
          'transport_type': {
              'id': 2,
              'name': 'Terrestre'
          }}]
      }
    }

    let(:account) { FactoryBot.create(:account) }
    let(:country_id) { 1 }

    it 'Getting couriers using coverages' do
      origin_commune_id = 1
      destiny_commune_id = 2
      allow_any_instance_of(::PricesService::Coverages).to receive(:coverages).and_return(coverages)
      response = Coverages::Courier.new({ account: account }).availables_by_origin_and_destiny(country_id, origin_commune_id, destiny_commune_id)
      expect(response[:from]['chilexpress']).to eq('ARICA TEST')
      expect(response[:to]['chilexpress']).to eq('CAMARONES')
    end

    it 'Getting couriers using coverages with empty results' do
      origin_commune_id = 3
      destiny_commune_id = 3
      allow_any_instance_of(::PricesService::Coverages).to receive(:coverages).and_return({ data: [] })
      response = Coverages::Courier.new({ account: account }).availables_by_origin_and_destiny(country_id, origin_commune_id, destiny_commune_id)
      expect(response[:from]).to eq({})
      expect(response[:to]).to eq({})
    end

    it 'Getting couriers using null params' do
      allow_any_instance_of(::PricesService::Coverages).to receive(:coverages).and_return({ data: [] })
      response = Coverages::Courier.new({ account: nil }).availables_by_origin_and_destiny(nil, nil, nil)
      expect(response[:from]).to eq({})
      expect(response[:to]).to eq({})
    end
  end
end
