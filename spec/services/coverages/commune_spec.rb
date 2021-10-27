require 'pry'
require 'rails_helper'

describe Coverages::Commune do
  context 'commune coverage service' do
    let(:couriers) {
      {  
        from: {
          'chilexpress': 'ARICA',
          'bluexpress': 'ARICA'
        },
        to: {
          'chilexpress': 'CAMARONES',
          'bluexpress': 'CAMARONES'
        }
      }.with_indifferent_access
    }

    let(:account) { FactoryBot.create(:account, :backoffice_courier_enabled) }
    let(:commune) { FactoryBot.create(:commune) }
    let(:country_id) { 1 }

    it 'Is available chilexpress in the commune using coverages' do
      origin_commune_id = 1
      courier_name = 'chilexpress'
      allow_any_instance_of(::Coverages::Courier).to receive(:availables_by_origin_and_destiny).and_return(couriers)
      response = Coverages::Commune.new({ account: account, commune: commune }).available_by_origin_and_courier_name?(country_id, origin_commune_id, courier_name)
      expect(response).to eq(true)
    end

    it 'Is available bluexpress in the commune using coverages' do
      origin_commune_id = 1
      courier_name = 'bluexpress'
      allow_any_instance_of(::Coverages::Courier).to receive(:availables_by_origin_and_destiny).and_return(couriers)
      response = Coverages::Commune.new({ account: account, commune: commune }).available_by_origin_and_courier_name?(country_id, origin_commune_id, courier_name)
      expect(response).to eq(true)
    end

    it 'Is not available starken in the commune using coverages' do
      origin_commune_id = 1
      courier_name = 'starken'
      allow_any_instance_of(::Coverages::Courier).to receive(:availables_by_origin_and_destiny).and_return(couriers)
      response = Coverages::Commune.new({ account: account, commune: commune }).available_by_origin_and_courier_name?(country_id, origin_commune_id, courier_name)
      expect(response).to eq(false)
    end
  end
end
