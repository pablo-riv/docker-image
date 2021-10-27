module EmergencyRates
  module Sellers
    class Seller
      def initialize(attributes)
        @object =
          case attributes[:seller].first[0]
          when 'shopify' then Shopify.new(attributes)
          when 'woocommerce' then Woocommerce.new(attributes)
          when 'prestashop' then Prestashop.new(attributes)
          else
            raise NotImplementedError
          end
      end

      def instance
        @object
      end
    end
  end
end
