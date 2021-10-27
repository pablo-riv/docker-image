module Calculator
  class Parcel
    # OOP
    include HTTParty
    include Calculator::Error
    include Calculator::Courier
    include Calculator::Algorithm
    include Calculator::Origin
    include Calculator::Destiny
    include Calculator::Api

    base_uri Rails.configuration.opit_endpoint
    attr_accessor :attributes, :errors

    def initialize(attributes)
      @attributes = attributes
      @errors = []
    end

    def calculate
      validate_attributes
      raise @errors.pop unless @errors.size.zero?

      result = prices
      @errors << CantGetPrice unless result['prices'].present?
      raise @errors.pop unless @errors.size.zero?

      prices_result = HashWithIndifferentAccess.new(result.parsed_response)
      { algorithm: algorithm,
        algorithm_days: algorithm_days,
        subscription: subscription,
        apply_courier_discount: apply_courier_discount,
        courier_for_client: couriers,
        prices: prices_result[:prices],
        lower_price: prices_result[:lower_price],
        higesth_price: prices_result[:higesth_price],
        spreadsheet_versions: prices_result[:spreadsheet_versions],
        spreadsheet_versions_destinations: prices_result[:spreadsheet_versions_destinations] }
    rescue => e
      raise e
    end

    def width
      raise if @attributes[:width].to_f < 1

      @attributes[:width].to_f
    rescue StandardError => _e
      10.0
    end

    def length
      raise if @attributes[:length].to_f < 1

      @attributes[:length].to_f
    rescue StandardError => _e
      10.0
    end

    def height
      raise if @attributes[:height].to_f < 1

      @attributes[:height].to_f
    rescue StandardError => _e
      10.0
    end

    def weight
      raise if @attributes[:weight].to_f < 0.01

      @attributes[:weight].to_f
    rescue StandardError => _e
      1.0
    end

    def company
      @attributes[:company]
    end

    def opit
      @attributes[:opit]
    end

    def subscription
      @attributes[:subscription]
    end

    def apply_courier_discount
      @attributes[:apply_courier_discount]
    end

    private

    def validate_attributes
      @errors << UndefinedDestiny unless destiny.present?
    end
  end
end
