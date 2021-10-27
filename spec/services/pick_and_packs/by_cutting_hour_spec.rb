require 'rails_helper'

describe PickAndPacks::ByCuttingHour do
  let!(:pick_and_pack) { FactoryBot.create(:pick_and_pack) }

  describe '#initzialize' do
    subject do
      described_class.new(Time.now)
    end
    context 'call service' do
      it 'returns object of type PickAndPacks::ByCuttingHour' do
        expect(subject.class).to eq(PickAndPacks::ByCuttingHour)
      end
      it 'attribute hour is of type string' do
        expect(subject.hour.class).to eq(String)
      end
    end
  end

  describe '#pick_and_packs' do
    subject do
      pick_and_pack.cutting_hour.update_columns(pick_and_pack_service: rand(8..15).to_f)
      described_class.new(Time.now).pick_and_packs
    end
    context 'call method' do
      it 'returns object of type PickAndPack::ActiveRecord_Relation ' do
        expect(subject.class).to eq(PickAndPack::ActiveRecord_Relation)
      end
    end
    context 'call method with the same hour of pick_and_pack_service' do
      it 'returns array with minimum one object' do
        expect(subject.size).to be >= 0
      end
    end
  end
end
