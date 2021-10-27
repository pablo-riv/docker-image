require 'rails_helper'

describe Zendesk::CourierInfo do
  let(:valid_courier) { 'chilexpress' }
  let(:invalid_courier) { 'chilexpresss' }
  let(:couriers_symbol) { CourierOperationalInformation.by_kind.map { |info| info.courier.symbol }.compact }
  let(:data) do
    courier = Courier.find_by(symbol: 'chilexpress')
    courier.courier_operational_informations.unique_by_kind
  end
  let(:courier_info) { Zendesk::CourierInfo.new('chilexpress') }
  let(:invalid_operational_information) { FactoryBot.build(:courier_operational_information) }

  context '#courier_data' do
    it 'expect valid parameter courier symbol' do
      courier_data = Zendesk::CourierInfo.new(valid_courier).courier_data
      expect(courier_data.is_a?(Hash)).to be_truthy
      expect(courier_data).to include(
        email: ['ttoro@ext.chilexpress.cl'],
        agent_name: 'Estimada Tamar',
        requester_id: '408598187213'
      )
    end

    it 'expect invalid parameter courier symbol' do
      courier_data = Zendesk::CourierInfo.new(invalid_courier).courier_data
      expect(courier_data).to be_falsey
    end
  end
  context '#couriers_symbol' do
    it 'return array of symbols with courier names' do
      couriers = %w[
        starken
        chilexpress
        bluexpress
      ]
      expect(couriers_symbol.is_a?(Array)).to be_truthy
      expect(couriers_symbol).to match_array(couriers)
    end
  end

  context '#valid_courier_name?' do
    it 'return true if the courier is contained in the array' do
      result = couriers_symbol.include?(valid_courier)
      expect(result).to be_truthy
    end

    it 'return false if the courier is not contained in the array' do
      result = couriers_symbol.include?(invalid_courier)
      expect(result).to be_falsey
    end
  end

  context '#validate_fields' do
    it 'validate all fields of record' do
      result = courier_info.send(:validate_fields, data)
      expect(result).to be_truthy
    end

    it 'validate all fields and return ArgumentError' do
      expect { courier_info.send(:validate_fields, invalid_operational_information) }.to raise_error(ArgumentError)
    end
  end
end
