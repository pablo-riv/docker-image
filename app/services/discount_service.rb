class DiscountService
  attr_accessor :object
  def initialize(object)
    @object = object
  end

  def percent
    subscription.present? ? validate : 0
  end

  def amount
    discount = subscription.present? ? validate : 0
    return 0 unless @object[:price].present?

    (@object[:price] * (discount / 100)).round
  end

  def shipment
    return 0 unless @object[:price].present?

    (@object[:price] - amount).round
  end

  private

  def validate
    return 0 unless subscription.present?

    courier_selected || !apply_courier_discount ? subscription.prices['total_discount'] / 2 : subscription.prices['total_discount']
  end

  def courier_selected
    @object[:courier_selected]
  end

  def subscription
    @object[:subscription]
  end

  def apply_courier_discount
    @object[:apply_courier_discount]
  end

  def price
    @object[:price]
  end
end
