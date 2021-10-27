class AlgorithmService
  attr_accessor :properties, :errors

  def initialize(properties)
    @properties = properties
    @errors = []
  end

  def calculate
    raise 'Precios no encontrados' unless prices.present?

    calculate_discount
    discrimine
    decorate_response
  end

  private

  def decorate_response
    properties.delete_if { |key| %i(apply_courier_discount subscription higesth_price setting spreadsheet_versions spreadsheet_versions_destinations).include?(key) }
  end

  def calculate_discount
    prices.map do |price|
      discount = DiscountService.new(price: price['price'],
                                     apply_courier_discount: apply_courier_discount,
                                     subscription: subscription,
                                     courier_selected: courier_selected)
      price['price'] = discount.shipment
      price
    end
    lower_price['price'] = DiscountService.new(price: lower_price['price'],
                                               apply_courier_discount: apply_courier_discount,
                                               subscription: subscription,
                                               courier_selected: courier_selected).shipment
  end

  def discrimine
    # lower prices logic based on algorithm
    price =
      if courier_selected
        prices.find { |p| p['courier']['name'] == courier_for_client }
      elsif algorithm == 2
        price_x_days = prices.select { |p| p['days'] <= algorithm_days }
                             .sort { |p| - p['price'] }
        price_x_days[0]
      else
        lower_price
      end
    prices
    properties[:lower_price] = price
  end

  def algorithm
    properties[:algorithm].to_i
  end

  def algorithm_days
    properties[:algorithm_days].to_i
  end

  def prices
    @properties[:prices].map { |value| value.except!('cost') }
  rescue StandardError => e
    []
  end

  def lower_price
    @properties[:lower_price].except!('cost')
  rescue StandardError => e
    []
  end

  def higesth_price
    @properties[:higesth_price] # based on params returned from opit: highest_price
  end

  def spreadsheet_versions
    @properties[:spreadsheet_versions]
  end

  def apply_courier_discount
    @properties[:apply_courier_discount]
  end

  def spreadsheet_versions_destinations
    @properties[:spreadsheet_versions_destinations]
  end

  def courier_selected
    courier_for_client.present? || @properties[:courier_selected].present?
  end

  def courier_for_client
    @properties[:courier_for_client].try(:downcase)
  end

  def subscription
    @properties[:subscription]
  end
end
