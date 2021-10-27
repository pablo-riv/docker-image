require 'rails_helper'

RSpec.describe ReturnPackage, type: :model do
  let(:commune) { FactoryBot.create(:commune, name: 'Las Condes') }
  let(:return_package) { FactoryBot.create(:return_package, commune: commune) }
  subject { return_package.full_address }

  it 'can create origin package with valid attributes' do
    expect(FactoryBot.create(:return_package)).to be_valid.and be_an_instance_of(ReturnPackage)
  end

  it 'validate return_package attributes' do
    return_package = FactoryBot.create(:return_package)
    expect(return_package.update_attributes(commune_id: nil)).to be false
    expect(return_package.update_attributes(package_id: nil)).to be false
    expect(return_package.update_attributes(return_id: nil)).to be false
  end

  describe '#full_address' do
    it { is_expected.to eq "#{return_package.street} #{return_package.number}, #{return_package.commune_name}, #{return_package.commune.country_name}"&.titleize }
  end
end
