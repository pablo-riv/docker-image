require 'rails_helper'

RSpec.describe DestinationPackage, type: :model do
  let(:commune) { FactoryBot.create(:commune, name: 'Las Condes') }
  let(:destination_package) { FactoryBot.create(:destination_package, commune: commune) }
  subject { destination_package.full_address }

  it 'can create destination_package with valid attributes' do
    expect(FactoryBot.create(:destination_package)).to be_valid.and be_an_instance_of(DestinationPackage)
  end

  it 'validate destination_package attributes' do
    destination_package = FactoryBot.create(:destination_package)
    expect(destination_package.update_attributes(commune_id: nil)).to be false
    expect(destination_package.update_attributes(package_id: nil)).to be false
  end

  describe '#full_address' do
    it { is_expected.to eq "#{destination_package.street} #{destination_package.number}, #{destination_package.commune_name}, #{destination_package.commune.country_name}"&.titleize }
  end
end
