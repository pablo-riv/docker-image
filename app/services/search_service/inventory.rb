module SearchService
  class Inventory
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def search
      inventories = data['inventory_activities'].select { |inventory| (from_date..to_date).cover?(inventory['created_at'].to_date) }
      inventories = inventories.select { |inventory| filter(inventory) } if query.present? && value.present?

      { total: inventories.size, inventories: RecursiveOpenStruct.new(inventories, recurse_over_arrays: true) }
    end

    private

    def data
      ::FulfillmentService.movements(company_id, types, page, per)
    end

    def company_id
      properties[:company_id]
    end

    def page
      properties[:page]
    end

    def per
      properties[:per]
    end

    def types
      JSON.parse(properties[:types] || '[1,2,3]')
    end

    def query
      properties[:query]
    end

    def value
      properties[:value]
    end

    def from_date
      properties[:from_date].try(:to_date)
    end

    def to_date
      properties[:to_date].try(:to_date).try(:at_end_of_day)
    end

    def filter(inventory)
      case query
      when 'package_id', 'id' then inventory[query] == value.to_i
      else
        inventory[query] == value
      end
    end
  end
end
