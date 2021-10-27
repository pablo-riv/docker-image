module Charges
  class Fulfillment < Charges::Charge
    def initialize(properties)
      super(properties)
    end

    private

    def make_report(charges)
      report = CSV.generate(encoding: 'UTF-8'.encoding) do |csv|
        csv << [I18n.t('activerecord.attributes.charges.fulfillment.date'), I18n.t('activerecord.attributes.charges.fulfillment.in'),
                I18n.t('activerecord.attributes.charges.fulfillment.stock'), I18n.t('activerecord.attributes.charges.fulfillment.out'),
                I18n.t('activerecord.attributes.charges.fulfillment.shipping_cost'), I18n.t('activerecord.attributes.charges.fulfillment.other_services'),
                I18n.t('activerecord.attributes.charges.fulfillment.discounts'), I18n.t('activerecord.attributes.charges.fulfillment.total')]
        (@properties[:kind] == 'yearly' ? charges : charges[:inventories]).each do |charge|
          csv << [charge[:date], charge[:in], charge[:stock], charge[:out], charge[:shipments], charge[:other_services], charge[:discounts], charge[:total]]
        end
      end

      report
    end
  end
end
