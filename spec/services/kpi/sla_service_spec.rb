require 'pry'
require 'rails_helper'
describe Kpis::SlaService do
  context 'Calculate SLA Object' do
    before do
      @company = FactoryBot.create(:company, :default)
      @couriers = %w(chilexpress starken muvsmart chileparcels motopartner bluexpress shipit)
      @sla_service = Kpis::SlaService.new({company: @company})
      @current_slas = Kpi.where(kpiable_type: 'Company', kpiable_id: @company.id, entity_type: 'Package', kind: :sla, associated_date: Date.current.beginning_of_day)
    end

    it '#recalculate_sla' do
      @current_slas.destroy_all
      expect(@sla_service.recalculate_sla).to be_an_instance_of(Array)
      expect(@current_slas.count).to eq(7)
      expect(@current_slas.pluck(:associated_courier)).to eq(@couriers)
    end
  end
end