require 'pry'
require 'rails_helper'

describe Couriers::CourierStarken do
  context 'When a shipment go via Starken' do
    before do
      commune = FactoryBot.create(:commune)
      @courier = Couriers::CourierStarken.new('Domicilio', false, 'reference', commune.id)
    end

    it '#destiny' do
      expect(@courier.destiny).to eq 'domicilio'
    end

    it '#payable' do
      expect(@courier.payable).to be false
    end

    it '#valid_shipment' do
      expect(@courier.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @courier.payable = true
      @courier.destiny = 'Chilexpress'
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @courier.payable = true
      @courier.destiny = 'Starken-Turbus'
      expect(@courier.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @courier.payable = false
      @courier.destiny = 'Starken-Turbus'
      expect(@courier.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @courier.destiny = 'Chilexpress'
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @courier.payable = true
      expect(@courier.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @courier.destiny = 'dhl'
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @courier.destiny = 'correoschile'
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @courier.destiny = ''
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end
  end
end
