require 'pry'
require 'rails_helper'

describe Couriers::CourierChilexpress do
  context 'When a shipment go via Chilexpress' do
    before do
      commune = FactoryBot.create(:commune)
      @courier = Couriers::CourierChilexpress.new('Domicilio', false, 'reference', commune.id)
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
      @courier.destiny = 'Chilexpress'
      expect(@courier.valid_shipment).to be true
    end

    it '#valid_shipment' do
      @courier.payable = true
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorNotDestinyPayable
    end

    it '#valid_shipment' do
      @courier.destiny = 'dhl'
      expect { @courier.valid_shipment }.to raise_error Couriers::Error::ErrorDestiny
    end

    it '#valid_shipment' do
      @courier.destiny = 'starken-turbus'
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
