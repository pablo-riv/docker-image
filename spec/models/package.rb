require 'rails_helper'

RSpec.describe Package, type: :model do
  context '.valid_for_manifest' do
    it 'validates relation and show only packages valid for manifest' do
      packages_pickup = FactoryBot.build(:packages_pickup, deleted_at: Time.current)
      packages_pickup.save
      result = Package.valid_for_manifest(packages_pickup.pickup.id)
      expect(result.present?).to be_falsey
    end

    it 'validates relation and return packages when delete_at attr is nil' do
      packages_pickup = FactoryBot.build(:packages_pickup)
      packages_pickup.save
      result = Package.valid_for_manifest(packages_pickup.pickup.id)
      expect(result.present?).to be_truthy
    end
  end

  describe '#courier_url' do
    context 'when courier_for_client is muvsmart' do
      let(:package) { FactoryBot.create(:package, tracking_number: '123') }
      it 'includes tracking.99minutos.com' do
        package.courier_for_client = 'muvsmart'
        expect(package.courier_url).to include('tracking.99minutos.com')
      end
    end
    context 'when is blank' do
      let(:package) { FactoryBot.create(:package, tracking_number: '') }
      it 'returns "Sin tracking"' do
        expect(package.courier_url).to eq('Sin tracking')
      end
    end
  end
end
