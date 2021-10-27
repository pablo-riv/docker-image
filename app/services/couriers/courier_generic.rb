module Couriers
  class CourierGeneric
    attr_accessor :object, :errors

    def initialize(name: '', type_of_destiny: '', payable: false, reference: '', commune_id: 0)
      @errors = []
      @object =
        case name&.downcase
        when 'chilexpress' then Couriers::CourierChilexpress.new(type_of_destiny, payable, reference, commune_id)
        when 'starken' then Couriers::CourierStarken.new(type_of_destiny, payable, reference, commune_id)
        when 'dhl' then Couriers::CourierDhl.new(type_of_destiny, payable, reference, commune_id)
        when 'correoschile', 'correos chile' then Couriers::CourierCorreosChile.new(type_of_destiny, payable, reference, commune_id)
        when 'muvsmart', '99minutos' then Couriers::CourierMuvsmart.new(type_of_destiny, payable, reference, commune_id)
        when 'chileparcels' then Couriers::CourierChileparcels.new(type_of_destiny, payable, reference, commune_id)
        when 'motopartner' then Couriers::CourierMotopartner.new(type_of_destiny, payable, reference, commune_id)
        when 'bluexpress' then Couriers::CourierBluexpress.new(type_of_destiny, payable, reference, commune_id)
        when 'shippify' then Couriers::CourierShippify.new(type_of_destiny, payable, reference, commune_id)
        when 'fulfillment delivery' then Couriers::CourierFulfillmentDelivery.new(type_of_destiny, payable, reference, commune_id)
        else
          Couriers::CourierShipit.new(type_of_destiny, payable, reference, commune_id)
        end
    end

    def instance
      @object
    end
  end
end
