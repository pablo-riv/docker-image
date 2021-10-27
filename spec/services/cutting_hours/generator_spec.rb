require 'pry'
require 'rails_helper'

describe CuttingHours::Generator do
  context 'calculate_days to Package' do
    it 'can calculate default days to operation_cutting_hour for package' do
      days = CuttingHours::Generator.new.calculate_days
      expect(days).to be_a(Integer)
    end

    it 'can calculate branch_office days to operation_cutting_hour for package' do
      branch_office = FactoryBot.create(:company).default_branch_office
      days = CuttingHours::Generator.new(model: branch_office).calculate_days
      expect(days).to be_a(Integer)
    end
  end

  context 'cutting_hour calculation from object' do
    it 'can calculate branch_office' do
      branch_office = FactoryBot.create(:company).default_branch_office
      cutting_hour = CuttingHours::Generator.new(model: branch_office).calculate_cutting_hour
      expect(cutting_hour).to be_a(String)
    end

    it 'can calculate area' do
      area = FactoryBot.create(:area, distribution_center: FactoryBot.create(:distribution_center))
      cutting_hour = CuttingHours::Generator.new(model: area).calculate_cutting_hour
      expect(cutting_hour).to be_a(String)
    end

    it 'can calculate distribution_center' do
      distribution_center = FactoryBot.create(:distribution_center)
      cutting_hour = CuttingHours::Generator.new(model: distribution_center).calculate_cutting_hour
      expect(cutting_hour).to be_a(String)
    end

    it 'can calculate company' do
      company = FactoryBot.create(:company, :default)
      cutting_hour = CuttingHours::Generator.new(model: company).calculate_cutting_hour
      expect(cutting_hour).to be_a(String)
    end

    it 'can calculate commune' do
      commune = FactoryBot.create(:commune)
      cutting_hour = CuttingHours::Generator.new(model: commune).calculate_cutting_hour
      expect(cutting_hour).to be_a(String)
    end

    it 'can calculate default dc model' do
      cutting_hour = CuttingHours::Generator.new.calculate_cutting_hour
      expect(cutting_hour).to be_a(String)
    end

    it 'can calculate fulfillment service' do
      cutting_hour = CuttingHours::Generator.new(service: 'ff').calculate_cutting_hour
      expect(cutting_hour).to be_a(String)
    end

    it 'can calculate lavelling service' do
      cutting_hour = CuttingHours::Generator.new(service: 'll').calculate_cutting_hour
      expect(cutting_hour).to be_a(String)
    end
  end
end
