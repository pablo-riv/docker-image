module Analytics
  class Collect
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = errors
    end

    def exec
      data =
        case model
        when 'shipments' then shipments
        when 'orders' then orders
        when 'supports' then supports
        when 'pickups' then pickups
        else
          []
        end
      HashWithIndifferentAccess.new(current: extract(periods.current.from..periods.current.to, data),
                                    last: extract(periods.last.from..periods.last.to, data),
                                    total: data)
    end

    def model
      @properties[:model]
    end

    def periods
      @properties[:periods]
    end

    def company
      @properties[:company]
    end

    def shipments
      ::Package.left_outer_joins(:accomplishment).where(branch_office_id: company.branch_offices.ids)
               .select("packages.id, packages.courier_for_client, packages.total_price, packages.created_at AT TIME ZONE 'utc' AT TIME ZONE 'chile/continental' AS created_at, accomplishments.delivery_accomplishment AS accomplishments, packages.sub_status AS sub_status, packages.is_sandbox, packages.reference, packages.delivery_time, packages.branch_office_id")
               .load
    end

    def orders
      ::Order.where(company_id: company.id).load
    end

    def supports
      ::Support.where(account_id: company.current_account.id, requester_type: 'shipit_client')
               .select("supports.id, supports.created_at AT TIME ZONE 'utc' AT TIME ZONE 'chile/continental' AS created_at, supports.metrics, supports.status")
               .load
    end

    def pickups
      ::Pickup.includes(:packages)
              .where(packages: { branch_office_id: company.branch_offices.ids })
              .load
    end

    def extract(range, array = [])
      array.select { |data| range.cover?(data.created_at.to_date) }
    end
  end
end
