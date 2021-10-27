module Charges
  class Period
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def exec
      case properties[:kind]
      when 'yearly' then yearly
      when 'monthly' then monthly
      else
        raise 'No period kind specify { "yearly" || "monthly" }'
      end
    end

    def monthly
      properties[:date].at_beginning_of_month..properties[:date].at_end_of_month.at_end_of_day
    end

    def yearly
      properties[:date].at_beginning_of_year..properties[:date].at_end_of_year.at_end_of_day
    end
  end
end
