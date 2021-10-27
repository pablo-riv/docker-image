FactoryBot.define do
  factory :courier_operational_information do
    emails { %w[hlagos@chilexpress.cl kbarriga@chilexpress.cl] }
    main_email { 'ttoro@ext.chilexpress.cl' }
    greeting { 'Estimada Tamar' }
    shipping_reference { 'Encomienda/s' }
    courier_id { Courier.find_by(symbol: 'chilexpress').id }
    kind { 0 }
    zendesk_id { '' }
  end
end
