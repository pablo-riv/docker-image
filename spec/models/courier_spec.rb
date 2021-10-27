require 'rails_helper'

RSpec.describe Courier, type: :model do
  describe '#services_by_courier' do
    subject { Courier.services_by_courier(courier, company_id) }
    
    context 'when courier is priority' do
      let(:courier) { 'chilexpress' }
      let(:company_id) { 1 }

      it { expect(subject.dig('priority')).should_not be_nil }
    end

    context 'when courier is sdd' do
      let(:courier) { 'moova' }
      let(:company_id) { 1 }

      it { expect(subject.dig('same_day')).should_not be_nil }
    end
  end
end
