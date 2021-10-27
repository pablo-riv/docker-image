require 'rails_helper'
require 'pry'

RSpec.describe Kpi, type: :model do
  context 'Build SLA Object' do
    before do
      @company = FactoryBot.create(:company, :default)
      @couriers = %w(chilexpress starken muvsmart chileparcels motopartner bluexpress shipit)
      @default_sla = FactoryBot.create(:kpi, :default_sla)
      @valid_attributes = { kpiable_type: 'Company',
                            kpiable_id: @company.id,
                            associated_date: Date.current,
                            associated_courier: @couriers.sample,
                            aggregation: :day,
                            entity_type: 'Package',
                            entity_last_checked_id: nil,
                            entity_accumulated_quantity: 0,
                            kind: :sla }
    end

    it 'Should create a KPI with all information' do
      sla = Kpi.new(@valid_attributes)
      expect(sla.save).to be true
      expect(sla).to be_an_instance_of(Kpi)
    end

    it 'Should not create a KPI without all required information' do
      sla = Kpi.new
      expect(sla.save).to be false
    end

    it 'Should not create a KPI without Kpiable Type' do
      attributes = @valid_attributes.except(:kpiable_type)
      sla = Kpi.new(attributes)
      expect(sla.save).to be false
    end

    it 'Should not create a KPI without Kpiable ID' do
      attributes = @valid_attributes.except(:kpiable_id)
      sla = Kpi.new(attributes)
      expect(sla.save).to be false
    end

    it 'Should not create a KPI without associated_date' do
      attributes = @valid_attributes.except(:associated_date)
      sla = Kpi.new(attributes)
      expect(sla.save).to be false
    end

    it 'Should not create a KPI without associated courier' do
      attributes = @valid_attributes.except(:associated_courier)
      sla = Kpi.new(attributes)
      expect(sla.save).to be false
    end

    it 'Should not create a KPI with time aggregation nil' do
      attributes = @valid_attributes
      attributes[:aggregation] = nil
      sla = Kpi.new(attributes)
      expect(sla.save).to be false
    end

    it "Should create a KPI with aggregation 'global' in case of not given" do
      attributes = @valid_attributes.except(:aggregation)
      sla = Kpi.create(attributes)
      expect(sla.aggregation).to eq('global')
    end

    it 'Should not create a KPI without entity_type' do
      attributes = @valid_attributes.except(:entity_type)
      sla = Kpi.new(attributes)
      expect(sla.save).to be false
    end

    it 'Should create a KPI without entity_last_checked_id' do
      attributes = @valid_attributes.except(:entity_last_checked_id)
      sla = Kpi.new(attributes)
      expect(sla.save).to be true
      expect(sla.entity_last_checked_id).to be_nil
    end

    it 'Should not create a KPI without entity_accumulated_quantity' do
      attributes = @valid_attributes.except(:entity_accumulated_quantity)
      sla = Kpi.new(attributes)
      expect(sla.save).to be false
    end

    it 'Should create a KPI with entity_accumulated_quantity as numeric' do
      sla = Kpi.create(@valid_attributes)
      expect(sla.entity_accumulated_quantity).to be_an(Numeric)
      expect(sla.entity_accumulated_quantity).to be >= 0
    end

    it 'Should not create a KPI without kind' do
      attributes = @valid_attributes.except(:kind)
      sla = Kpi.new(attributes)
      expect(sla.save).to be false
    end
  end
  context 'Kpi methods' do
    before do
      @company = FactoryBot.create(:company, :default)
      @couriers = %w(chilexpress starken muvsmart chileparcels motopartner bluexpress shipit)
      @default_sla = FactoryBot.create(:kpi, :default_sla)
      @default_slas = FactoryBot.create_list(:kpi, 10, :default_sla)
      @current_slas = Kpi.where(kpiable_type: 'Company', kpiable_id: @company.id, entity_type: 'Package', kind: :sla)
      @valid_attributes = { kpiable_type: 'Company',
                            kpiable_id: @company.id,
                            associated_date: Date.current,
                            associated_courier: @couriers.sample,
                            aggregation: :day,
                            entity_type: 'Package',
                            entity_last_checked_id: nil,
                            entity_accumulated_quantity: 0,
                            kind: :sla }
    end

    describe '#global_sla' do
      it 'Should respond with a number' do
        global_sla = Kpi.global_sla
        expect(global_sla).to be_an(Numeric)
        expect(global_sla).to be >= 0
      end

      it 'Should respond with a positive number if there are positive slas' do
        global_sla = Kpi.global_sla
        positive_global_sla = @default_slas.pluck(:value).any? { |v| v.positive? }
        expect(global_sla).to be_an(Numeric)
        expect(global_sla).to be > 0 if positive_global_sla
      end
    end

    describe '#last_calculated_package_id' do
      it 'Should respond with an id if a Company has previous KPI' do
        attributes = { kpiable_type: @default_sla.kpiable_type,
                       kpiable_id: @default_sla.kpiable_id,
                       entity_type: @default_sla.entity_type,
                       date_to: @default_sla.associated_date,
                       kind: :sla }
        last_calculated_package_id = Kpi.last_calculated_package_id(attributes)
        expect(last_calculated_package_id).to be_an(Numeric)
      end

      it 'Should respond with nil if a Company has no packages' do
        @current_slas.delete_all
        sla = Kpi.create(@valid_attributes)
        attributes = { kpiable_type: sla.kpiable_type,
                       kpiable_id: sla.kpiable_id,
                       entity_type: sla.entity_type,
                       date_to: sla.associated_date,
                       kind: :sla }
        last_calculated_package_id = Kpi.last_calculated_package_id(attributes)
        expect(last_calculated_package_id).to be_nil
      end
    end
  end
end
