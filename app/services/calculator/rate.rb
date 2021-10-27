
module Calculator
  class Rate
    include Error

    attr_accessor :rate, :errors
    def initialize(rate: {})
      @rate = rate
      @errors = []
    end

    def process
      validate_attributes
      raise @errors.pop unless @errors.size.zero?

      calculate_discount
      filter_algorithm
      decorate_response
    end

    private

    def validate_attributes
      @errors << CantGetPrice unless prices.present?
    end

    def calculate_discount
      prices.map do |price|
        price['price'] = discount(price: price['price'])
        price
      end
      lower_price['price'] = discount(price: lower_price['price'])
    end

    def discount(price: 0)
      Discount.new(price: price,
                   apply_courier_discount: apply_courier_discount,
                   subscription: subscription,
                   courier_selected: courier_selected).shipment
    end

    def decorate_response
      @rate.delete_if do |key|
        %i[is_payable apply_courier_discount subscription higesth_price setting spreadsheet_versions spreadsheet_versions_destinations prices_spreadsheet costs_spreadsheet].include?(key)
      end
    end

    def filter_algorithm
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
      @rate[:lower_price] = price
    end

    def algorithm
      @rate[:algorithm].to_i
    end

    def algorithm_days
      @rate[:algorithm_days].to_i
    end

    def prices
      @rate[:prices].map { |value| value.except!('cost') }
    rescue StandardError => _e
      []
    end

    def lower_price
      @rate[:lower_price].except!('cost')
    rescue StandardError => _e
      []
    end

    def higesth_price
      @rate[:higesth_price] # based on params returned from opit: highest_price
    end

    def spreadsheet_versions
      @rate[:spreadsheet_versions]
    end

    def apply_courier_discount
      @rate[:apply_courier_discount]
    end

    def spreadsheet_versions_destinations
      @rate[:spreadsheet_versions_destinations]
    end

    def courier_selected
      courier_for_client.present? || @rate[:courier_selected].present?
    end

    def courier_for_client
      @rate[:courier_for_client].try(:downcase)
    end

    def subscription
      @rate[:subscription]
    end
  end
end
