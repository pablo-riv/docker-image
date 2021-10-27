require 'faker'
require 'pry'

FactoryBot.define do
  factory :company do
    trait :default do
      name { Faker::Name.name }
      created_at { 2.year.ago }
      phone { Faker::Number.number(8) }
      run { Faker::Number.number(7) }
      after(:build) do |company|
        address = Address.create!(FactoryBot.build(:address).attributes)
        company.entity.update_attributes(billing_address_id: address.id, address_id: address.id)
        Setting.create(service_id: 1, company_id: company.id)
        Setting.create(service_id: 3, company_id: company.id)
        Setting.create(service_id: 6, company_id: company.id)
        Setting.create(service_id: 9, company_id: company.id)
      end
      after(:create) do |company|
        company.address_books.create(addressable_type: 'Origin',
                                     addressable_id: company.address.id,
                                     full_name: Faker::Name.name,
                                     phone: Faker::PhoneNumber.subscriber_number(8),
                                     email: Faker::Internet.email,
                                     default: true,
                                     address_id: company.address.id,
                                     company_id: company.id)
      end
    end
    
    trait :big do
      name { Faker::Name.name }
      created_at { 2.year.ago }
      phone { Faker::Number.number(8) }
      run { Faker::Number.number(7) }
      before(:create) do |company|
        address = Address.create!(FactoryBot.build(:address).attributes)
        company.entity.update_attributes(billing_address_id: address.id, address_id: address.id)
        entity = company.entity
        Account.create!(email: Faker::Internet.email, password: '121212', password_confirmation: '121212', entity_id: entity.id)
        create(:branch_office, company: company)
      end
      after(:create) do |company|
        opit = Setting.create(service_id: 1, company_id: company.id)
        opit.update_columns(configuration: { 'opit' => { 'key' => '',
                                                         'secret_key' => '',
                                                         'price' => '',
                                                         'couriers' => [{ 'cxp' => { 'destinies' => [], 'is_cost' => true, 'is_price' => true,  'available' => true } },
                                                                        { 'stk' => { 'destinies' => [], 'is_cost' => false, 'is_price' => true, 'available' => true } },
                                                                        { 'cc'  => { 'destinies' => [], 'is_cost' => true, 'is_price' => false, 'available' => true } },
                                                                        { 'dhl' => { 'available' => true } }],
                                                         'is_new_courier_price_enabled' => true,
                                                         'algorithm' => 2,
                                                         'algorithm_days' => '2' } })
        Setting.create(service_id: 6, company_id: company.id)
        FactoryBot.build(:plan)
        subscription = FactoryBot.build(:subscription)
        subscription.company_id = company.id
        subscription.save
        %w[in_preparation in_route delivered failed by_retired].each_with_index do |state, index|
          company.mail_notifications.create(tracking: true, state: index)
        end
      end
    end

    trait :medium do
      name { Faker::Name.name }
      created_at { 2.year.ago }
      phone { Faker::Number.number(8) }
      run { Faker::Number.number(7) }
      before(:create) do |company|
        address = Address.create!(FactoryBot.build(:address).attributes)
        company.entity.update_attributes(billing_address_id: address.id, address_id: address.id)
        entity = company.entity
        Account.create!(email: Faker::Internet.email, password: '121212', password_confirmation: '121212', entity_id: entity.id)
        create(:branch_office, company: company)
      end
      after(:create) do |company|
        Setting.create(service_id: 1, company_id: company.id)
        Setting.create(service_id: 6, company_id: company.id)
        %w[in_preparation in_route delivered failed by_retired].each_with_index do |state, index|
          company.mail_notifications.create(tracking: true, state: index)
        end
      end
    end

    trait :newbie do
      name { Faker::Name.name }
      created_at { 30.business_days.before(Date.current) }
      phone { Faker::Number.number(8) }
      run { Faker::Number.number(7) }
      before(:create) do |company|
        address = Address.create!(FactoryBot.build(:address).attributes)
        company.entity.update_attributes(billing_address_id: address.id, address_id: address.id)
        entity = company.entity
        Account.create!(email: Faker::Internet.email, password: '121212', password_confirmation: '121212', entity_id: entity.id)
        create(:branch_office, company: company)
      end
      after(:create) do |company|
        Setting.create(service_id: 1, company_id: company.id)
        Setting.create(service_id: 6, company_id: company.id)
        %w[in_preparation in_route delivered failed by_retired].each_with_index do |state, index|
          company.mail_notifications.create(tracking: true, state: index)
        end
      end
    end

    trait :old do
      name { Faker::Name.name }
      created_at { 2.year.ago }
      phone { Faker::Number.number(8) }
      run { Faker::Number.number(7) }
      before(:create) do |company|
        address = Address.create!(FactoryBot.build(:address).attributes)
        company.entity.update_attributes(billing_address_id: address.id, address_id: address.id)
        entity = company.entity
        Account.create!(email: Faker::Internet.email, password: '121212', password_confirmation: '121212', entity_id: entity.id)
        create(:branch_office, company: company)
      end
      after(:create) do |company|
        Setting.create(service_id: 1, company_id: company.id)
        Setting.create(service_id: 6, company_id: company.id)
        %w[in_preparation in_route delivered failed by_retired].each_with_index do |state, index|
          company.mail_notifications.create(tracking: true, state: index)
        end
      end
    end
  end
end