class AnalyticsService
  attr_accessor :object, :errors, :dates
  def initialize(object)
    @object = object
    @errors = []
    @from_date = object[:date][:from_date]
    @to_date = object[:date][:to_date]
    @period_length = object[:date][:period_length]
    @last_from_date = object[:date][:last_from_date]
    @last_to_date = object[:date][:last_to_date]
  end

  def process
    {
      all_packages: set_all_packages,
      account: account,
      company: company,
      period_length: @period_length,
      dates: set_dates,
      packages: set_packages,
      orders: set_orders,
      supports: set_supports,
      notifications: set_notifications,
      charts: set_charts
    }
  end

  private

  def set_dates
    {
      from_date: @from_date,
      to_date: @to_date,
      last_from_date: @last_from_date,
      last_to_date: @last_to_date
    }
  end

  def set_all_packages
    {
      all_current_packages: all_current_packages,
      all_last_packages: all_last_packages
    }
  end

  def set_packages
    {
      current_period_packages: packages,
      last_period_packages: last_period_packages
    }
  end

  def set_orders
    {
      current_period_orders: orders,
      last_period_orders: last_period_orders
    }
  end

  def set_supports
    {
      current_period_supports: supports,
      last_period_supports: last_period_supports
    }
  end

  def set_notifications
    {
      current_period_notifications: alerts,
      last_period_notifications: last_period_alerts
    }
  end

  def set_charts
    {
      packages: packages_charts,
      orders: orders_charts
    }
  end

  def all_current_packages
    packages = Package.delivered.joins(:accomplishment).dump_between_dates_analytics(from: @from_date, to: @to_date).load
    @current_packages = packages.select('packages.id, packages.branch_office_id, packages.courier_for_client,
      packages.created_at, accomplishments.total_accomplishment AS total')
  end

  def all_last_packages
    packages = Package.delivered.joins(:accomplishment).dump_between_dates_analytics(from: @last_from_date, to: @last_to_date).load
    @last_packages = packages.select('packages.id, packages.branch_office_id, packages.courier_for_client,
      packages.created_at, accomplishments.total_accomplishment AS total')
  end

  def packages
    @company_packages = @current_packages.where(branch_office_id: company.branch_offices.ids).distinct
    @packages = @company_packages.joins(:branch_office, address: :commune).select('packages.id, packages.branch_office_id, packages.courier_for_client,
      packages.created_at, accomplishments.total_accomplishment AS total, communes.name AS commune_name')
  end

  def last_period_packages
    @last_company_packages = @last_packages.where(branch_office_id: company.branch_offices.ids).distinct
    @last_period_packages = @last_company_packages.joins(:branch_office, address: :commune)
  end

  def orders
    @orders = OrderService.where(company_id: company.id, day: (@from_date.to_date.at_beginning_of_day..@to_date.to_date.at_end_of_day))
    array_format_order(@orders)
  end

  def last_period_orders
    @last_period_orders = OrderService.where(company_id: company.id, day: (@last_from_date.to_date.at_beginning_of_day..@last_to_date.to_date.at_end_of_day))
    array_format_order(@last_period_orders)
  end

  def array_format_order(orders)
    orders_array = []
    orders.map { |order| orders_array << { id: order.id, day: order.day, total_price: order.total_price } }
  end

  def supports
    Support.where(account_id: account.id).between_dates(@from_date, @to_date)
  end

  def last_period_supports
    Support.where(account_id: account.id).between_dates(@last_from_date, @last_to_date)
  end

  def packages_charts
    packages_chart(current_period_packages: { packages: @company_packages, from: @from_date },
                   last_period_packages: { packages: @last_company_packages, from: @last_from_date })
  end

  def orders_charts
    orders_chart(current_period_orders: { orders: @orders, from: @from_date },
                 last_period_orders: { orders: @last_period_orders, from: @last_from_date })
  end

  def alerts
    @company_packages.joins('RIGHT OUTER JOIN alerts ON packages.id = alerts.package_id')
  end

  def last_period_alerts
    @last_company_packages.joins('RIGHT OUTER JOIN alerts ON packages.id = alerts.package_id')
  end

  def packages_chart(packages)
    packages_grouped = []
    packages.each do |key, value|
      current_period_date = value[:from].to_date
      data_by_day = value[:packages].group_by { |package| package.created_at.to_date }.map { |day, package| [day, package.count] }
      days_to_fill = @period_length
      data_count = Array.new(days_to_fill) do |day|
        current_iteration_date = current_period_date + day.days
        data = data_by_day.find { |day_packages| current_iteration_date == day_packages[0].to_date }
        data.present? ? [day, data[1]] : [day, 0]
      end
      acc = 0
      packages_grouped << { name: I18n.t("analytics.chart.periods.#{key}"),
                            data: data_count.map { |days, count| [days.to_s, acc += count.to_i] } }
    end
    packages_grouped
  end

  def orders_chart(orders)
    orders_grouped = []
    orders.each do |key, value|
      current_period_date = value[:from].to_date
      data_by_day = value[:orders].group_by { |order| order.day.to_date }.map { |day, order| [day, order.map(&:total_price).map(&:to_i).sum] }
      days_to_fill = @period_length
      data_count = Array.new(days_to_fill) do |day|
        current_iteration_date = current_period_date + day.days
        data = data_by_day.find { |day_orders| current_iteration_date == day_orders[0].to_date }
        data.present? ? [day, data[1]] : [day, 0]
      end
      acc = 0
      orders_grouped << { name: I18n.t("analytics.chart.periods.#{key}"),
                          data: data_count.map { |days, count| [days.to_s, acc += count.to_i] } }
    end
    orders_grouped
  end

  def company
    object[:company]
  end

  def account
    object[:account]
  end
end
