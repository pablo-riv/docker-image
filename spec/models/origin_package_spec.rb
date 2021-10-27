require 'rails_helper'

RSpec.describe OriginPackage, type: :model do
  let(:commune) { FactoryBot.create(:commune, name: 'Las Condes') }
  let(:origin_package) { FactoryBot.create(:origin_package, commune: commune) }
  subject { origin_package.full_address }

  it 'can create origin package with valid attributes' do
    expect(FactoryBot.create(:origin_package)).to be_valid.and be_an_instance_of(OriginPackage)
  end

  it 'validate origin_package attributes' do
    origin_package = FactoryBot.create(:origin_package)
    expect(origin_package.update_attributes(commune_id: nil)).to be false
    expect(origin_package.update_attributes(package_id: nil)).to be false
    expect(origin_package.update_attributes(origin_id: nil)).to be false
  end

  describe '#full_address' do
    it { is_expected.to eq "#{origin_package.street} #{origin_package.number}, #{origin_package.commune_name}, #{origin_package.commune.country_name}"&.titleize }
  end
end
