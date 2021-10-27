module EmergencyRates
  module Sellers
    class Base
      attr_accessor :attributes, :errors
      def initialize(attributes)
        @seller = Seller.new(attributes).instance
        @errors = []
      end

      def send_rate
        @seller.upload_rate
      end
    end
  end
end
