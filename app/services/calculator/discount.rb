module Calculator
  class Discount
    attr_accessor :attributes
    def initialize(attributes)
      @attributes = attributes
    end

    def percent
      subscription.present? ? validate : 0
    end

    def amount
      discount = subscription.present? ? validate : 0
      return 0 unless @attributes[:price].present?

      (@attributes[:price] * (discount / 100)).round
    end

    def shipment
      return 0 unless @attributes[:price].present?

      (@attributes[:price] - amount).round
    end

    private

    def validate
      return 0 unless subscription.present?

      courier_selected || !apply_courier_discount ? subscription.prices['total_discount'] / 2 : subscription.prices['total_discount']
    end

    def courier_selected
      @attributes[:courier_selected]
    end

    def subscription
      @attributes[:subscription]
    end

    def apply_courier_discount
      @attributes[:apply_courier_discount]
    end

    def price
      @attributes[:price]
    end
  end
end
