require 'faker'
FactoryBot.define do
  factory :branch_office do
    name { Faker::Name.name }
    company { FactoryBot.create(:company, :default) }
    is_default { false }
    before(:create) do |branch_office|
      area = FactoryBot.create(:area)
      hero = Hero.find_by(id: 1) || FactoryBot.create(:hero, id: 1)
      region = Region.create(name: Faker::Name.name)
      commune = Commune.all.sample || Commune.create!(name: Faker::Name.name, region_id: region.id, couriers_availables: {"dhl"=>"LAS CONDES", "starken"=>"LAS CONDES", "chilexpress"=>"LAS CONDES", "correoschile"=>"LAS CONDES"})
      address = FactoryBot.create(:address)
      distribution_center = DistributionCenter.create(name: Faker::Name.name, cutting_hours: { ff: '11:00', ll: '19:00', pp: '11:00' }, address_id: address.id)
      branch_office.cutting_hour = FactoryBot.create(:cutting_hour)
      branch_office.entity.save
      branch_office.entity.update_attributes(billing_address_id: address.id, address_id: address.id, actable_type: 'BranchOffice')
    end
  end
end
