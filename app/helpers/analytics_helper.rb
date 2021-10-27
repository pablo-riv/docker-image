module AnalyticsHelper
  def calculate_percent(current_period, last_period)
    return '0%' if current_period.to_f == last_period.to_f || (last_period == '-' || current_period == '-')
    return '100%' if last_period.to_f.zero?

    ((current_period.to_f - last_period.to_f) / last_period.to_f * 100).round(1).to_s + '%'
  end

  def count_quantity(object)
    object.size || 0
  end

  def shipit_sla(packages)
    data = packages.select('packages.id, packages.branch_office_id').load
    calculate_sla(data)
  end

  def calculate_sla(packages)
    accomplished = packages.select(&:total).size
    unaccomplished = packages.reject(&:total).size
    return '-' if accomplished.zero? && unaccomplished.zero?

    sla = (accomplished.to_f / (accomplished + unaccomplished) * 100).round(1)
    format_number(sla, '%')
  end

  def name_element(type, package)
    return I18n.t('analytics.packages.table.without_courier') unless package[0].present?
    return courier_icon(package[0]) if type == 'courier'

    package[0]['name'].titleize
  end

  def current_total_orders(orders)
    return 0 if orders.empty?

    @current_orders_ammount = orders.first.map { |o| o[:total_price].to_i }.sum
  end

  def last_total_orders(orders)
    return 0 if orders.empty?

    @last_orders_ammount = orders.first.map { |o| o[:total_price].to_i }.sum
  end

  def current_average_orders(orders)
    orders.size.zero? ? 0 : (@current_orders_ammount / orders.size)
  end

  def last_average_orders(orders)
    orders.size.zero? ? 0 : @last_orders_ammount / orders.size
  end

  def average_orders(orders)
    (orders.size.to_f / @data[:period_length]).round(1)
  end

  def ordered_communes(packages)
    packages.group_by(&:commune).sort_by { |_k, v| -v.size }
  end

  def ordered_couriers(packages)
    packages.group_by { |courier| courier.courier_for_client.downcase unless courier.courier_for_client.blank? }.sort_by { |_k, v| -v.size }
  end

  def format_number(period, concat_var)
    concat_var == '$' ? concat_var + ' ' + number_with_delimiter(period, delimiter: '.') : number_with_delimiter(period, delimiter: '.', separator: ',') + concat_var
  end

  def alerts_quantity(alerts)
    alerts.size || 0
  end

  def average_alerts(alerts, packages)
    packages.size.zero? ? 0 : (alerts.size.to_f / packages.size).round(1)
  end

  def integrated_seller
    @data[:company].any_integrations?
  end
end
