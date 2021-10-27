class CalendarService
  COURIERS = ['chilexpress', 'dhl', 'starken', 'correoschile', 'correos_de_chile', 'muvsmart', 'glovo', 'motopartner', 'chileparcels', 'bluexpress', 'shippify', 'empty_courier', ''].freeze
  STATES = [0, 1, 3, 4, 9, 10].freeze
  CURRENT_DATE = Date.current
  attr_accessor :attributes, :errors

  def initialize(attributes)
    @attributes = attributes
    @errors = []
  end

  def calendar
    search_shipments = shipments
    {
      shipments: search_shipments,
      total: total(search_shipments)
    }
  end

  private

  def courier
    return COURIERS unless attributes[:courier].present?
    return COURIERS if attributes[:courier].try(:downcase) == 'all'

    attributes[:courier].split(',')
  end

  def state
    return STATES unless attributes[:status].present?
    return STATES if attributes[:status].try(:downcase) == 'all'

    attributes[:status].split(',').map { |state| translate_status(state) }
  end

  def branch_offices
    attributes[:branch_offices]
  end

  def to_date
    return CURRENT_DATE.at_end_of_month unless @attributes[:date].present?

    @attributes[:date].to_date.at_end_of_month
  end

  def from_date
    return CURRENT_DATE.at_beginning_of_month unless @attributes[:date].present?

    @attributes[:date].to_date.at_beginning_of_month
  end

  def translate_status(status)
    case status
    when 'in_preparation' then 0
    when 'in_route' then 1
    when 'failed' then 3
    when 'by_retired' then 4
    when 'ready_to_dispatch' then 9
    when 'dispatched' then 10
    end
  end

  def shipments
    Package.select_calendar.left_outer_joins(:check, :supports)
           .where("packages.operation_date BETWEEN ? AND ? AND LOWER(coalesce(packages.courier_for_client,'empty_courier')) IN (?)", from_date, to_date, courier)
           .where(status: state, branch_office_id: branch_offices).not_sandbox.not_test.no_returned.order('packages.operation_date ASC')
           .group_by { |shipment| shipment.operation_date.day }.map { |day, data| { day => data.reject(&:monitor_condition).group_by(&:status) } }
           .inject({}) { |response, data| response.merge(data) }
  end

  def total(search_shipments)
    search_shipments.map { |day, shipment_array| shipment_array.map { |status, shipment| shipment.size } }.flatten.sum
  end
end
