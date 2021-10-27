json.analytics do
  unless @analytics.shipments.nil?
    json.shipments do
      json.total @analytics.shipments.total
      json.cost do
        json.current number_to_currency(@analytics.shipments.cost.current)
        json.last number_to_currency(@analytics.shipments.cost.last)
        json.percent @analytics.shipments.cost.percent
        json.total number_to_currency(@analytics.shipments.cost.total)
        json.average number_to_currency(@analytics.shipments.cost.average.round)
      end
      json.couriers @analytics.shipments.couriers
    end
  end
  unless @analytics.orders.nil?
    json.orders do
      json.total @analytics.orders.total
      json.sells do
        json.current number_to_currency(@analytics.orders.sells.current)
        json.last number_to_currency(@analytics.orders.sells.last)
        json.percent @analytics.orders.sells.percent
        json.total number_to_currency(@analytics.orders.sells.total)
      end
      unless @analytics.shipments.nil?
        json.sell_cost @analytics.orders.sell_cost.call(cost: { current: @analytics.shipments.cost.current,
                                                              last: @analytics.shipments.cost.last,
                                                              total: @analytics.shipments.cost.total },
                                                        sell: { current: @analytics.orders.sells.current,
                                                                last: @analytics.orders.sells.last,
                                                                total: @analytics.orders.sells.total })
      end
    end
  end
end
