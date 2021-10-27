require 'rails_helper'
require 'pry'

describe Shipments::ShipmentService do
  context 'ShipmentService create method' do
    before do
      FactoryBot.create(:distribution_center)
      @company = FactoryBot.create(:company, :big)
      @branch_office = FactoryBot.build(:branch_office)
      @branch_office.company_id = @company.id
      @branch_office.save
      @account = FactoryBot.create(:account)
      @salesman = FactoryBot.create(:salesman)
      @company.update(first_owner_id: @company.id, second_owner_id: @company.id)
      @account.update(entity_id: @company.entity.id)
      @order = FactoryBot.build(:order)
      @order.company_id = @company.id
      @order.save
      @fulfillment = nil
      @automatization = Setting.create(service_id: 9, company_id: @company.id)
      @opit = FactoryBot.create(:setting, :opit)
      @notification = FactoryBot.create(:setting, :notification)
      @couriers = Prices.new(@account).couriers
      @courier_branch_offices = Prices.new(@account).branch_offices
      @skus = []
      shipment = @order.transform_shipment(@fulfillment).merge(
        company: @company,
        branch_office: @branch_office,
        fulfillment: @fulfillment,
        opit: @opit,
        notification: @notification,
        couriers: @couriers,
        courier_branch_offices: @courier_branch_offices,
        skus: @skus
      ).with_indifferent_access
      @shipment = Shipments::ShipmentService.new(shipment).create
    end

    it '#shipment_reference' do
      expect(@shipment.email).to be_an_instance_of(String)
    end

    it '#shipment_reference' do
      expect(@shipment.reference).to be_an_instance_of(String)
    end

    it '#shipment_full_name' do
      expect(@shipment.full_name).to be_an_instance_of(String)
    end

    it '#shipment_length' do
      expect(@shipment.length).to be_an_instance_of(Float)
    end

    it '#shipment_height' do
      expect(@shipment.height).to be_an_instance_of(Float)
    end

    it '#shipment_width' do
      expect(@shipment.width).to be_an_instance_of(Float)
    end

    it '#shipment_weight' do
      expect(@shipment.weight).to be_an_instance_of(Float)
    end

    it '#shipment_cellphone' do
      expect(@shipment.cellphone).to be_an_instance_of(String)
    end

    it '#shipment_is_payable' do
      expect(@shipment.is_payable).to be_in([true, false])
    end

    it '#shipment_packing' do
      expect(@shipment.packing).to be_an_instance_of(String)
    end

    it '#shipment_shipping_type' do
      expect(@shipment.shipping_type).to be_an_instance_of(String)
    end

    it '#shipment_destiny' do
      expect(@shipment.destiny).to be_an_instance_of(String)
    end

    it '#shipment_courier_for_client' do
      expect(@shipment.courier_for_client).to be_an_instance_of(String)
      expect(@shipment.courier_for_client).to be_in(['chilexpress', 'starken', 'bluexpress', 'motopartner', 'chileparcels', 'muvsmart', 'dhl', 'correoschile', 'shippify'])
    end

    it '#shipment_courier_selected' do
      expect(@shipment.courier_selected).to be_in([true, false])
    end

    it '#shipment_delivery_time' do
      expect(@shipment.delivery_time).to be_an_instance_of(String)
      expect(@shipment.delivery_time.to_i).to be >= 0
    end

    it '#shipment_platform' do
      expect(@shipment.platform).to be_an_instance_of(String)
    end

    it '#shipment_address' do
      expect(@shipment.address).to be_an_instance_of(Address)
    end

    it '#shipment_is_sandbox' do
      expect(@shipment.is_sandbox).to be_in([true, false])
    end

    it '#shipment_branch_office_id' do
      expect(@shipment.branch_office_id).to be_an_instance_of(Integer)
    end

    it '#shipment_algorithm' do
      expect(@shipment.algorithm).to be_an_instance_of(Integer)
      expect(@shipment.algorithm).to be >= 0
    end

    it '#shipment_algorithm_days' do
      expect(@shipment.algorithm_days).to be_an_instance_of(Integer)
      expect(@shipment.algorithm_days).to be >= 0
    end

    it '#shipment_courier_branch_office_id' do
      expect(@shipment.courier_branch_office_id).to be_an_instance_of(Integer).or(be_nil)
    end

    it '#shipment_service' do
      expect(@shipment.service).to be_an_instance_of(String)
    end

    it '#shipment_shipping_price' do
      expect(@shipment.shipping_price).to be_an_instance_of(Float)
    end

    it '#shipment_shipping_cost' do
      expect(@shipment.shipping_cost).to be_an_instance_of(Float)
    end

    it '#shipment_total_is_payable' do
      expect(@shipment.total_is_payable).to be_an_instance_of(Float)
    end

    it '#shipment_total_price' do
      expect(@shipment.total_price).to be_an_instance_of(Float)
    end

    it '#shipment_without_courier' do
      expect(@shipment.without_courier).to be_in([true, false])
    end

    it '#shipment_insurance' do
      expect(@shipment.insurance).to be_an_instance_of(Insurance)
    end

    it '#shipment_mongo_order_seller' do
      expect(@shipment.mongo_order_seller).to be_an_instance_of(String)
    end

    it '#shipment_order_id' do
      expect(@shipment.order_id).to be_an_instance_of(Integer)
    end

    it '#shipment_seller_order_id' do
      expect(@shipment.seller_order_id).to be_an_instance_of(String)
    end

    it '#shipment_processed_by_beetrack' do
      expect(@shipment.processed_by_beetrack).to  be_in([true, false])
    end

    it '#shipment_reference_into_branch_office' do
      expect(@shipment.reference_into_branch_office).to be("#{@branch_office.name}_#{@shipment.reference}")
    end
  end
end
