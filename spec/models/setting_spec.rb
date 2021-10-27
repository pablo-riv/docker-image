require 'rails_helper'

RSpec.describe Setting, type: :model do
  describe '#current_template_couriers' do
    subject { Setting.new.current_template_couriers(courier, country) }
    
    context 'when arguments are nil' do
      let(:courier) { nil }
      let(:country) { nil }

      it { is_expected.to eq({}) }
    end

    context 'when the country argument is blank' do
      let(:courier) { 'chilexpress' }
      let(:country) { nil }

      it { expect(subject['acronym']).to eq('cxp') }
    end

    context 'when the country argument is for chile' do
      let(:courier) { 'chilexpress' }
      let(:country) { 'cl' }

      it { expect(subject['acronym']).to eq('cxp') }
      it { expect(subject['origin']).to eq('LAS CONDES') }
    end

    context 'when the country argument is for mexico' do
      let(:courier) { 'muvsmart_mx' }
      let(:country) { 'mx' }

      it { expect(subject['origin']).to eq('SAN ANGEL - ALVARO OBREGON') }
    end
  end

  describe '#countries_yml' do
    subject { Setting.new.countries_yml }
    
    context 'call to method' do
      it { is_expected.should_not be_nil }
      it { expect(subject.dig('base_tcc')).should_not be_nil }
      it { expect(subject.dig('base_tcc', 'cl')).should_not be_nil }
      it { expect(subject.dig('base_tcc', 'mx')).should_not be_nil }
    end

  end

  describe '#country_base_tcc' do
    subject { Setting.new.country_base_tcc(country) }
    
    context 'when arguments are nil' do
      let(:country) { nil }

      it { expect(subject['origin']).to eq('LAS CONDES') }
    end

    context 'when the country argument is for chile' do
      let(:country) { 'cl' }

      it { expect(subject['origin']).to eq('LAS CONDES') }
    end

    context 'when the country argument is for mexico' do
      let(:country) { 'mx' }

      it { expect(subject['origin']).to eq('SAN ANGEL - ALVARO OBREGON') }
    end
  end

end
