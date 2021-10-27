require 'rails_helper'

describe ManifestService do
  subject(:object) { described_class.new({}) }
  let(:pickup) { FactoryBot.create(:pickup) }
  let(:package) { FactoryBot.create(:package) }

  describe '#dissociate_packages' do
    it 'validates dissociated packages without records' do
      expect(object.send(:dissociate_packages, pickup)).to eq([])
    end
    it ' validates dissociated packages method' do
      packages_pickup = FactoryBot.create(:packages_pickup)
      result = object.send(:dissociate_packages, packages_pickup.pickup)
      expect(result.present?).to be_truthy
      expect(result.first.id).to eq(packages_pickup.id)
      expect(result.first.deleted_at).not_to be_nil
    end
  end
end
