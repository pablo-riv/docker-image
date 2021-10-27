module Couriers
  class CourierFulfillmentDelivery < Couriers::Courier
    def initialize(destiny, payable, reference, commune_id)
      super(destiny, payable, reference, commune_id)
    end

    def valid_shipment
      raise Error::ErrorFulfillmentDeliveryDestiny.new(reference.to_s) unless ['retiro cliente', 'despacho retail'].include?(destiny.downcase)

      true
    end
  end
end
