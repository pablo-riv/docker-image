class Negotiation < ApplicationRecord
  ## RELATIONS
  belongs_to :company
  ## ATTRIBUTES
  enum kind: { percent: 0, amount: 1 }

  ## CLASS METHODS
  ## PUBLIC METHODS

  def apply(prices = [])
    return [] unless prices.present?

    prices.map do |key, price|
      next unless %w(lower_price higesth_price prices).include?(key)

      price.is_a?(Array) ? price.map { |p| calculate(p) } : calculate(price)
    end
    prices
  end

  ## PRIVATE METHODS
  private

  def calculate(price)
    case self.kind
    when 'percent' then price['price'] +=  (price['price'] * (self.percent / 100)).round
    when 'amount' then price['price'] += self.amount
    else
      0
    end
    price
  end
end
