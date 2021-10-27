module Analytics
  class Period
    CURRENT_DATE = Date.current

    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def period
      @properties[:period].present? ? @properties[:period].to_i : 7
    end

    def periods
      RecursiveOpenStruct.new(current: { from: current_period_from,
                                         to: current_period_to },
                              last: { from: last_period_from,
                                      to: last_period_to })
    end

    def current_period_from
      (CURRENT_DATE - period.days).to_date
    end

    def current_period_to
      CURRENT_DATE.to_date
    end

    def last_period_from
      (CURRENT_DATE - (2 * period).days).to_date
    end

    def last_period_to
      (CURRENT_DATE - period.days).to_date
    end
  end
end
