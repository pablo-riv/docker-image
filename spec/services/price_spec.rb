require 'pry'
require 'rails_helper'

describe Price::Shipment do

  package_paid_shipit_stub = {
    id: 555555,
    total_price: 4000,
    shipping_price: 3500,
    shipping_cost: 1190,
    courier_for_client: 'chileparcels',
    packing: 'Bolsa Courier',
    material_extra: 500,
    is_paid_shipit: true,
    is_payable: false,
    insurance_price: 0,
    height: 10,
    width: 10,
    length: 10
  }

  package_payable_stub = {
    id: 555555,
    total_price: 4000,
    shipping_price: 3500,
    shipping_cost: 1190,
    courier_for_client: 'chileparcels',
    material_extra: 500,
    is_paid_shipit: false,
    is_payable: true,
    packing: 'Bolsa Courier',
    insurance_price: 0,
    height: 10,
    width: 10,
    length: 10
  }

  package_regular_stub = {
    id: 555555,
    total_price: 4000,
    shipping_price: 3500,
    shipping_cost: 1190,
    courier_for_client: 'chileparcels',
    packing: 'Bolsa Courier',
    material_extra: 500,
    is_paid_shipit: false,
    is_payable: false,
    insurance_price: 0,  
    height: 10,
    width: 10,
    length: 10
  }

  let(:package_paid_shipit) { package_paid_shipit_stub }
  let(:package_payable) { package_payable_stub }
  let(:package_regular) { package_regular_stub }

  it 'PaidShipit#calculate_prices' do
    prices = Price::Shipment.new(package_paid_shipit).calculate_prices
    expect(prices[:is_paid_shipit]).to be_truthy
    expect(prices[:total_price]).to equal(0)
    expect(prices[:shipping_price]).to equal(0)
    expect(prices[:total_is_payable]).to equal(0)
    expect(prices[:shipping_cost]).to be >= 0
    expect(prices[:material_extra]).to be >= 0
    expect(prices[:is_payable]).to be_falsey
  end

  it 'Payable#calculate_prices' do
    prices = Price::Shipment.new(package_payable).calculate_prices
    expect(prices[:is_payable]).to be_truthy
    expect(prices[:total_price]).to equal(prices[:total_is_payable] + prices[:material_extra] + prices[:insurance_price])
    expect(prices[:shipping_price]).to equal(0)
    expect(prices[:shipping_cost]).to equal(0)
    expect(prices[:total_is_payable]).to equal(1178)
    expect(prices[:is_paid_shipit]).to be_falsey
    expect(prices[:material_extra]).to be >= 0
  end

  it 'Regular#calculate_prices' do
    prices = Price::Shipment.new(package_regular).calculate_prices
    expect(prices[:total_price]).to equal(prices[:shipping_price] + prices[:material_extra] + prices[:insurance_price])
    expect(prices[:shipping_price]).to be >= 0
    expect(prices[:shipping_cost]).to be >= 0
    expect(prices[:total_is_payable]).to equal(0)
    expect(prices[:is_payable]).to be_falsey
    expect(prices[:is_paid_shipit]).to be_falsey
    expect(prices[:material_extra]).to be >= 0
  end
end
