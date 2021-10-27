require 'pry'
require 'rails_helper'

describe Couriers::CourierGeneric do
  context 'When a shipment go via Any Carrier' do
    before do
      commune = FactoryBot.create(:commune)
      @generic = Couriers::CourierGeneric.new(name: 'chilexpress',
                                              type_of_destiny: 'Domicilio',
                                              payable: false,
                                              reference: 'reference',
                                              commune_id: commune.id)
    end

    it '#destiny' do
      expect(@generic.destiny).to eq 'domicilio'
    end

    it '#payable' do
      expect(@generic.payable).to be false
    end

    it '#valid_shipment' do
      expect(@generic.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @generic.destiny = 'Chilexpress'
      expect(@generic.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @generic.payable = true
      expect { @generic.valid_shipment }.to raise_error Couriers::Error::ErrorNotDestinyPayable
    end

    it '#valid_shipment' do
      @generic.destiny = 'dhl'
      expect { @generic.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @generic.destiny = 'starken-turbus'
      expect { @generic.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @generic.destiny = 'correoschile'
      expect { @generic.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @generic.destiny = ''
      expect { @generic.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end
  end
end
