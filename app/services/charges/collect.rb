module Charges
  class Collect
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = errors
    end

    def exec
      case service
      when 'pick_and_pack' then pick_and_pack
      when 'fulfillment' then fulfillment
      else
        []
      end
    end

    def details
      data =
        case specific
        when 'subscriptions' then subscriptions
        when 'shipments' then
          arry = shipments.reject(&:is_returned).reject(&:is_payable)
          return { shipments: { data: Kaminari.paginate_array(arry).page(page).per(per), total: arry.size } }.with_indifferent_access
        when 'overcharges' then shipments.reject(&:is_returned).select(&:is_payable)
        when 'insurances' then with_insurance
        when 'returns' then shipments.select(&:is_returned).reject(&:is_payable)
        when 'fines' then fines
        when 'parkings' then parkings
        when 'paid_by_shipit' then paid_by_shipit
        when 'indemnify' then refunds_indemnify
        when 'commercial_discounts' then commercial_discounts
        when 'recurrent' then recurrent
        when 'invoices' then invoices
        when 'in_fulfillment', 'out_fulfillment', 'stock_fulfillment', 'others_fulfillment' then inventories
        else
          []
        end
      { specific => data }.with_indifferent_access
    end

    def service
      @properties[:service]
    end

    def specific
      @properties[:specific]
    end

    def periods
      @properties[:periods] # can be yearly / monthly
    end

    def company
      @properties[:company]
    end

    def pick_and_pack
      { taxs: taxs, subscriptions: subscriptions, shipments: shipments, base_charge: base_charge, fines: fines, parkings: parkings, refunds: refunds, commercial_discounts: commercial_discounts, premium: premium, recurrent: recurrent, invoices: invoices }
    end

    def fulfillment
      { taxs: taxs, subscriptions: subscriptions, shipments: shipments, inventories: inventories, premium: premium, recurrent: recurrent, invoices: invoices, commercial_discounts: commercial_discounts }
    end

    def shipments
      company.packages.where("packages.billing_date BETWEEN ? AND ?", periods.first, periods.last).no_paid_by_shipit.not_sandbox.not_test
             .left_outer_joins(:insurance, :address, address: :commune)
             .select("packages.id, packages.reference, packages.created_at AT TIME ZONE 'utc' AT TIME ZONE 'chile/continental' AS created_at, packages.billing_date, packages.full_name, packages.shipping_price,"\
                     'packages.material_extra, packages.is_returned, packages.is_payable, packages.courier_for_client as courier, '\
                     'packages.total_is_payable AS overcharge, packages.total_price AS total,'\
                     'packages.width, packages.weight, packages.length, packages.height, packages.volume_price, packages.items_count,'\
                     'packages.is_paid_shipit, packages.tracking_number, packages.discount_amount,'\
                     'addresses.street AS address_street, addresses.number AS address_number, communes.name AS address_commune_name,'\
                     'insurances.price AS insurance_total_price, insurances.extra AS insurance_extra, insurances.active AS insurance_active').order(id: :desc).load
    end

    def inventories
      company.charges.fullfilment.where(date: periods).order(date: :desc).load
    end

    def base_charge
      company.charges.base_by_periods(periods).select("charges.details ->> 'amount' AS base_charge, charges.date").load
    end

    def fines
      company.fines.pickup_failed.by_periods(periods).load
    end

    def parkings
      company.fines.parking.by_periods(periods).load
    end

    def refunds
      company.fines.refunds.by_periods(periods).load
    end

    def commercial_discounts
      ::Fine.select("fines.id, fines.amount, fines.cause, fines.comment, fines.created_at AT TIME ZONE 'utc' AT TIME ZONE 'chile/continental' AS created_at, fines.date, entities.name AS branch_office_name, CONCAT(people.first_name, ' ', people.last_name) AS salesman_name")
            .joins('INNER JOIN branch_offices ON branch_offices.id = fines.branch_office_id')
            .joins("INNER JOIN entities ON entities.actable_id = branch_offices.id AND LOWER(entities.actable_type) = 'branchoffice'")
            .joins('LEFT OUTER JOIN salesmen ON salesmen.id = fines.responsible')
            .joins("LEFT OUTER JOIN users ON users.actable_id = salesmen.id AND LOWER(users.actable_type) = 'salesman'")
            .joins('LEFT OUTER JOIN people ON users.person_id = people.id')
            .by_periods(periods).where('fines.charge_type = 3 AND fines.branch_office_id IN (?)', company.branch_offices.ids).load
    end

    def paid_by_shipit
      company.packages.where("packages.billing_date BETWEEN ? AND ?", periods.first, periods.last).not_sandbox.not_test.paid_by_shipit
             .left_outer_joins(:address, address: :commune)
             .select('packages.id, packages.reference, packages.created_at, packages.billing_date, packages.full_name, packages.shipping_price,'\
                     'packages.material_extra, packages.is_returned, packages.is_payable, packages.courier_for_client as courier, '\
                     'packages.total_is_payable AS overcharge, packages.total_price AS total,'\
                     'packages.width, packages.weight, packages.length, packages.height, packages.volume_price, packages.items_count,'\
                     'packages.is_paid_shipit, packages.paid_by_shipit_reason, packages.tracking_number, packages.discount_amount,'\
                     'addresses.street AS address_street, addresses.number AS address_number, communes.name AS address_commune_name').load
    end

    def refunds_indemnify
      company.fines.joins('LEFT OUTER JOIN packages ON packages.id = fines.package_id').refunds.by_periods(periods)
             .select("packages.id, packages.reference, packages.created_at AT TIME ZONE 'utc' AT TIME ZONE 'chile/continental' AS created_at, packages.billing_date, packages.full_name, packages.status, packages.sub_status, packages.is_paid_shipit, packages.paid_by_shipit_reason, fines.*")
    end

    def premium
      company.charges.premium.where(date: periods)
             .select("SUM(CAST(charges.details ->> 'amount' AS INTEGER)) AS amount, charges.date").group(:date).load
    end

    def recurrent
      company.charges.opit.where(date: periods).where("charges.details ->> 'type' = 'recurrent_charge'")
             .select("SUM(CAST(charges.details ->> 'amount' AS INTEGER)) AS amount, charges.date").group(:date).load
    end

    def invoices
      company.invoices.by_period(emit_date: periods).load
    end

    def subscriptions
      company.subscriptions.by_period(periods).load
    end

    def taxs
      Indicator.by_periods(periods).load
    end

    def with_insurance
      shipments.select(&:insurance_extra)
    end

    def per
      @properties[:per].presence || 100
    end

    def page
      @properties[:page].presence || 1
    end
  end
end
