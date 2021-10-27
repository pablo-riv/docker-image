require 'pry'
require 'rails_helper'

describe Couriers::CourierCorreosChile do
  context 'When a shipment go via Correos Chile' do
    before do
      commune = FactoryBot.create(:commune)
      @courier = Couriers::CourierCorreosChile.new('Domicilio', false, 'reference', commune.id)
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
      expect(@courier.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @courier.payable = true
      @courier.payable = 'Correoschile'
      expect(@courier.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @courier.destiny = 'chilexpress'
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @courier.destiny = 'Starken-Turbus'
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @courier.destiny = 'Dhl'
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end
  end
end
