require 'faker'
FactoryBot.define do
  factory :setting do
    email_alert { nil }
    email_notification { nil }
    service_id { 1 }
    is_default_price { true }
    default_courier { "cxp" }
    configuration { Setting.new(service_id: 1).define_base_config }

    trait :opit do
      email_alert { nil }
      email_notification { nil }
      service_id { 1 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 1).define_base_config }
    end

    trait :fullit do
      email_alert { nil }
      email_notification { nil }
      service_id { 2 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 2).define_base_config }
    end

    trait :pp do
      email_alert { nil }
      email_notification { nil }
      service_id { 3 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 3).define_base_config }
    end

    trait :fulfillment do
      email_alert { nil }
      email_notification { nil }
      service_id { 4 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 4).define_base_config }
    end

    trait :sd do
      email_alert { nil }
      email_notification { nil }
      service_id { 5 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 5).define_base_config }
    end

    trait :notification do
      email_alert { nil }
      email_notification { nil }
      service_id { 6 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 6).define_base_config }
    end

    trait :printers do
      email_alert { nil }
      email_notification { nil }
      service_id { 7 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 7).define_base_config }
    end

    trait :analytics do
      email_alert { nil }
      email_notification { nil }
      service_id { 8 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 8).define_base_config }
    end

    trait :automatizations do
      email_alert { nil }
      email_notification { nil }
      service_id { 9 }
      is_default_price { true }
      default_courier { "cxp" }
      configuration { Setting.new(service_id: 9).define_base_config }
    end
  end
end