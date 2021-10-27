module Charges
  class PickAndPack < Charges::Charge
    def initialize(properties)
      super(properties)
    end

    private

    def make_report(charges)
      report = CSV.generate(encoding: 'UTF-8'.encoding) do |csv|
        @properties[:kind] == 'yearly' ? yearly_report_data(charges, csv) : monthly_report_data(charges[:shipments], csv)
      end

      report
    end

    def monthly_report_data(shipments, csv = [])
      csv << [I18n.t('activerecord.attributes.charges.pick_and_pack.date'), I18n.t('activerecord.attributes.package.full_name'),
              I18n.t('activerecord.attributes.address.street'), I18n.t('activerecord.attributes.address.number'), I18n.t('activerecord.attributes.commune.name'), I18n.t('activerecord.attributes.package.reference'),
              I18n.t('activerecord.attributes.package.length'), I18n.t('activerecord.attributes.package.width'), I18n.t('activerecord.attributes.package.height'), I18n.t('activerecord.attributes.package.weight'),
              I18n.t('activerecord.attributes.package.items_count'), I18n.t('activerecord.attributes.package.tracking_number'), I18n.t('activerecord.attributes.package.volume'),
              I18n.t('activerecord.attributes.package.is_payable'), I18n.t('activerecord.attributes.package.shipping_price'), I18n.t('activerecord.attributes.package.material_extra'),
              I18n.t('activerecord.attributes.package.is_paid_shipit'), I18n.t('activerecord.attributes.package.total_is_payable'), I18n.t('activerecord.attributes.package.discount_amount'), I18n.t('activerecord.attributes.package.total_price')]
      shipments.each do |package|
        csv << [I18n.l(package.created_at, format: '%d/%m/%Y'), package.full_name, package.address_street, package.address_number,
                package.address_commune_name, package.reference, package.length, package.width, package.height, package.weight,
                package.items_count, package.tracking_number, package.volume_price, I18n.t(package.is_payable), package.shipping_price.try(:round),
                package.material_extra.try(:round), I18n.t(package.is_paid_shipit), package.overcharge.try(:round), package.discount_amount.try(:round), package.total.try(:round)]
      end
      csv
    end

    def yearly_report_data(totals, csv)
      csv << [I18n.t('activerecord.attributes.charges.pick_and_pack.totals.date'),
              I18n.t('activerecord.attributes.charges.pick_and_pack.totals.base'),
              I18n.t('activerecord.attributes.charges.pick_and_pack.totals.shippings'),
              I18n.t('activerecord.attributes.charges.pick_and_pack.totals.total_is_payable'),
              I18n.t('activerecord.attributes.charges.pick_and_pack.totals.other_service'),
              I18n.t('activerecord.attributes.charges.pick_and_pack.totals.discounts'),
              I18n.t('activerecord.attributes.charges.pick_and_pack.totals.resume')]
      totals.each do |total|
        csv << [total[:month], total[:base_charge], total[:shipping_price], total[:overcharge], total[:other_services], total[:refunds], total[:total]]
      end
      csv
    end

    def pick_and_pack
      # needs to calculate fines and parkings and return data
      { parkings: decorate_values(total_refunds(shipments)),
        total_pick_and_pack: total_extras(period.first.strftime('%m/%Y'), shipments) }
    end
  end
end
