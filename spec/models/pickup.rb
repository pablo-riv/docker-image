require 'rails_helper'

describe Pickup, type: :model do
  subject(:object) { described_class.new }
  let(:package) { FactoryBot.create(:package)}
  describe 'validates methods' do
    it '#sdd_couriers' do
      result = object.sdd_couriers
      expect(result).not_to be_empty
      expect(result).to include('moova', 'shippify')
    end

    it '#packages_with_invalid_courier' do
      packages_pickup = FactoryBot.create(:packages_pickup)
      expect(packages_pickup.pickup.packages_with_invalid_courier).not_to be_empty
    end
  end
end
