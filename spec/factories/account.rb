FactoryBot.define do
  factory :account do
    email { Faker::Internet.email }
    created_at { 1.year.ago }
    password { '123456789' }
    password_confirmation { '123456789' }
    id_printer { '566980' }
    entity_id { FactoryBot.create(:company, :default).entity.id }
    before(:create) do |account|
      create(:person, account: account)
      create(:branch_office, company_id: account.current_company.id, is_default: true)
    end
  end
  trait :backoffice_courier_enabled do
    after(:create) do |account|
      company = account.current_company
      setting = Setting.opit(company.id)
      setting.configuration['opit']['is_backoffice_couriers_enabled'] = true
      setting.update_columns(configuration: setting.configuration)
    end
  end
end

