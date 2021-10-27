module Price
  class Shipment

    PRICE_IS_PAYABLE = 990
    TAX = 1.19

    attr_accessor :properties
    def initialize(properties)
      @properties = properties
      @discount = calculate_discount
    end

    def calculate_prices
      prices =
        if is_paid_shipit
          paid_shipit_total_price
        elsif is_payable
          payable_total_price
        else
          regular_total_price
        end
      negotiation = calculate_negotiation
      prices[:total_price] += negotiation
      prices[:negotiation] = negotiation
      prices
    end

    private

    def paid_shipit_total_price
      { shipping_cost: shipping_cost,
        material_extra: material_extra,
        insurance_price: insurance_price,
        shipping_price: 0,
        total_price: 0,
        total_is_payable: 0,
        is_paid_shipit: is_paid_shipit,
        is_payable: is_payable,
        discount_amount: 0,
        discount_percent: 0 }
    end

    def payable_total_price
      { total_price: (total_is_payable + insurance_price + material_extra),
        total_is_payable: total_is_payable,
        material_extra: material_extra,
        insurance_price: insurance_price,
        shipping_price: 0,
        shipping_cost: 0,
        is_payable: is_payable,
        is_paid_shipit: is_paid_shipit,
        discount_amount: 0,
        discount_percent: 0 }
    end

    def regular_total_price
      { material_extra: material_extra,
        insurance_price: insurance_price,
        shipping_price: (shipping_price - @discount.amount),
        shipping_cost: shipping_cost,
        total_price: ((shipping_price - @discount.amount) + insurance_price + material_extra),
        total_is_payable: 0,
        is_payable: is_payable,
        is_paid_shipit: is_paid_shipit,
        discount_amount: @discount.amount,
        discount_percent: @discount.percent }
    end

    def is_paid_shipit
      properties[:is_paid_shipit] || false
    end

    def is_payable
      properties[:is_payable] || false
    end

    def insurance_price
      (properties[:insurance_price].present? ? properties[:insurance_price] : 0).round
    end

    def total_price
      properties[:total_price].round
    end

    def shipping_price
      properties[:shipping_price].try(:round)
    end

    def shipping_cost
      properties[:shipping_cost].try(:round)
    end

    def packing
      properties[:packing].try(:downcase) || 'sin empaque'
    end

    def height
      properties[:height].try(:to_f)
    end

    def width
      properties[:width].try(:to_f)
    end

    def length
      properties[:length].try(:to_f)
    end

    def material_extra
      Price::Packing.new(height: height, width: width, length: length, packing: packing).calculate
    end

    def total_is_payable
      (PRICE_IS_PAYABLE * TAX).round
    end

    def negotiation_kind
      properties[:negotiation_kind]
    end

    def subscription
      properties[:subscription]
    end

    def apply_courier_discount
      properties[:apply_courier_discount]
    end

    def negotiation_amount
      properties[:negotiation_amount].try(:to_f)
    end

    def courier_selected
      properties[:courier_selected]
    end

    def calculate_negotiation
      total_extra =
        case negotiation_kind
        when 'percent' then shipping_price * (negotiation_amount / 100)
        when 'amount' then negotiation_amount
        else
          0
        end
      total_extra.round
    end

    def calculate_discount
      DiscountService.new(price: shipping_price,
                          apply_courier_discount: apply_courier_discount,
                          subscription: subscription,
                          courier_selected: courier_selected)
    end
  end
end
