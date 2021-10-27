require 'pry'
require 'rails_helper'

describe HubspotService::Hubspot do
  context 'Build Hubspot Object' do
    before do
      @company = FactoryBot.create(:company, :big)
      @branch_offices = FactoryBot.create(:branch_office)
      @branch_offices.update_columns(company_id: @company)
      @account = FactoryBot.create(:account)
      @salesman = FactoryBot.create(:salesman)
      @company.update(first_owner_id: @company.id, second_owner_id: @company.id)
      @account.update(entity_id: @company.entity.id)
      @hubspot = HubspotService::Hubspot.new(company: @company, account: @account)
    end

    it '#hubsport_properties' do
      expect { @hubspot.hubsport_properties }.to raise_error(HubspotService::Error::NotImplemented)
    end

    it '#company' do
      expect(@hubspot.company).to be_an_instance_of(Company)
    end

    it '#account' do
      expect(@hubspot.account).to be_an_instance_of(Account)
    end

    it '#total_shipment' do
      expect(@hubspot.total_shipment).to be_an(Numeric)
      expect(@hubspot.total_shipment).to be >= 0
    end

    it '#total_daily_average' do
      expect(@hubspot.total_daily_average).to be_an(Numeric)
      expect(@hubspot.total_daily_average).to be >= 0
    end

    it '#last_delivery_day' do
      expect(@hubspot.last_delivery_day).to_not be_nil
    end

    it '#company_state' do
      expect(%w[Deudor Activo Inactivo]).to include(@hubspot.company_state)
    end

    it '#company_name' do
      expect(@hubspot.company_name).to_not be_nil
    end

    it '#company_website' do
      expect(@hubspot.company_website).to_not be_nil
    end

    it '#current_services' do
      expect(['Fulfillment', 'Labelling', 'Pick & Pack']).to include(@hubspot.current_services)
    end

    it '#first_name' do
      expect(@hubspot.first_name).to_not be_nil
    end

    it '#last_name' do
      expect(@hubspot.last_name).to_not be_nil
    end

    it '#dni' do
      expect(@hubspot.dni).to_not be_nil
    end

    it '#email' do
      expect(@hubspot.email).to_not be_nil
    end

    it '#email' do
      expect(@hubspot.email_domain).to_not be_nil
    end

    it '#phone' do
      expect(@hubspot.phone).to_not be_nil
    end

    it '#state' do
      expect(@hubspot.state).to_not be_nil
    end

    it '#region' do
      expect(@hubspot.region).to_not be_nil
    end

    it '#country' do
      expect(@hubspot.country).to_not be_nil
    end

    it '#packages_hope' do
      expect(@hubspot.packages_hope).to_not be_nil
      expect(@hubspot.packages_hope).to_not be_zero
    end

    it '#kam' do
      expect(@hubspot.packages_hope).to_not be_nil
      expect(@hubspot.packages_hope).to_not be_zero
    end

    it '#last_month_sales' do
      expect(@hubspot.last_month_sales).to_not be_nil
      expect(@hubspot.last_month_sales).to be >= 0
    end

    it '#created_at' do
      expect(@hubspot.created_at).to_not be_nil
      expect(@hubspot.created_at).to be_a(String)
    end

    it '#features' do
      expect(@hubspot.features).to_not be_nil
    end

    it '#sign_in_count' do
      expect(@hubspot.sign_in_count).to_not be_nil
    end

    it '#setup_percent' do
      expect(@hubspot.setup_percent).to_not be_nil
    end

    it '#integrations' do
      expect(@hubspot.integrations).to_not be_nil
    end

    it '#tickets' do
      expect(@hubspot.tickets).to_not be_nil
    end

    it '#total_support_tickets' do
      expect(@hubspot.total_support_tickets).to_not be_nil
      expect(@hubspot.total_support_tickets).to be >= 0
    end

    it '#email_contact' do
      expect(@hubspot.email_contact).to_not be_nil
    end

    it '#deactivated' do
      expect(@hubspot.deactivated).to be(false)
    end

    it '#deactivation_date' do
      expect(@hubspot.deactivation_date).to eq('')
    end

    it '#deactivation_reason' do
      expect(@hubspot.deactivation_reason).to eq('')
    end

    it '#deactivation_details' do
      expect(@hubspot.deactivation_details).to eq('')
    end
  end
end
