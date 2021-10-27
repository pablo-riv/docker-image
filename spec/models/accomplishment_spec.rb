require 'rails_helper'

RSpec.describe Accomplishment, type: :model do
  let(:commune) { FactoryBot.create(:commune) }
  let(:company) { FactoryBot.create(:company, :big) }
  let(:branch_office) { FactoryBot.create(:branch_office, company_id: company.id) }
  let(:package) { FactoryBot.create(:package, 
                                    branch_office_id: branch_office.id,
                                    address_attributes: { commune_id: commune.id,
                                                          street: 'Nuestra señora de los Ángeles',
                                                          number: '185',
                                                          complement: 'Oficina E' })
  }

  context '#process' do
    before do
      FactoryBot.create(:distribution_center)
      selected = package.left_outer_joins(:check)
                        .select("checks.in ->> 'created_at' AS in_created_at, checks.in ->> 'branch_office_id' AS in_branch_office_id,
                          checks.out ->> 'created_at' AS out_created_at, checks.out ->> 'tracking_number' AS out_tracking_number,
                          packages.id, packages.created_at, packages.mongo_order_id,
                          packages.courier_status_updated_at, packages.delayed, packages.delivery_time")
      @accomplishment_data = Accomplishment.process([selected], company)
    end

    it 'client preparation should be correct' do
      if package.mongo_order_id.blank?
        expect(@accomplishment_data[:client_preparation_accomplishment]).to be true
      else
        expect(@accomplishment_data[:client_preparation_accomplishment]).to be false
      end
    end

    it 'hero should be correct' do
      if !package.check.blank? && !package.in['created_at'].blank? && 1.business_days.after(package.created_at).to_date <= package.in['created_at'].to_date
        expect(@accomplishment_data[:hero_pickup_accomplishment]).to be true
      else
        expect(@accomplishment_data[:hero_pickup_accomplishment]).to be false
      end
    end

    it 'first mile should be correct' do
      if !package.check.blank? && !package.out['tracking_number'].blank? && !package.in['branch_office_id'].blank? && package.out['created_at'].to_date == package.in['created_at'].to_date
        expect(@accomplishment_data[:first_mile_accomplishment]).to be true
      else
        expect(@accomplishment_data[:first_mile_accomplishment]).to be false
      end
    end

    it 'delivery should be correct' do
      if !package.delayed && !package.delivery_time.blank? && package.delivery_time.to_i.business_days.after(package.created_at.to_date) <= package.courier_status_updated_at.to_date
        expect(@accomplishment_data[:delivery_accomplishment]).to be true
      else
        expect(@accomplishment_data[:delivery_accomplishment]).to be false
      end
    end
  end
end
