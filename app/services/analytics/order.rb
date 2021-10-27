module Analytics
  class Order < Analytic
    CHARTS = %w[total].freeze
    def initialize(properties)
      super(properties)
    end

    CHARTS.each do |chart|
      define_method "#{chart}_chart".to_sym do
        public_send("#{chart}_serial")
      end
    end

    def metrics
      current_sells = sum_sells(current)
      last_sells = sum_sells(last)
      callback = lambda do |object|
        { current: percent(object[:cost][:current], object[:sell][:current]),
          last: percent(object[:cost][:last], object[:sell][:last]),
          average: number_to_currency(average(object[:cost][:total], object[:sell][:total])) }
      end
      RecursiveOpenStruct.new(orders: { total: { current: current.size,
                                                 last: last.size,
                                                 percent: percent(current.size, last.size),
                                                 total: total.size },
                                        sells: { current: current_sells,
                                                 last: last_sells,
                                                 percent: percent(current_sells, last_sells),
                                                 total: sum_sells(total) },
                                        sell_cost: callback })
    end

    def sum_sells(data = [])
      return 0 if data.size.zero?

      data.map { |o| o.payment['total'].to_f }.sum
    end

    def total_serial
      chart_serials('sells')
    end

    def sell_cost_chart(cost = [], sell = [])
      return [] unless cost.present? || sell.present?

      (1..days).map do |day|
        last_date = (periods.last.from + (day.days - 1))
        current_date = (periods.current.from + (day.days - 1))
        cost_last = calculate_chart(filter_serials(cost[:last], last_date), 'cost')
        cost_current = calculate_chart(filter_serials(cost[:current], current_date), 'cost')
        last_sells = calculate_chart(filter_serials(sell[:last], last_date), 'sells')
        current_sells = calculate_chart(filter_serials(sell[:current], current_date), 'sells')
        { name: day,
          last: percent(cost_last, last_sells),
          current: percent(cost_current, current_sells) }
      end
    end
  end
end
