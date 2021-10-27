module Couriers
  class CourierShippify < Couriers::Courier
    def initialize(destiny, payable, reference, commune_id)
      super(destiny, payable, reference, commune_id)
    end

    def valid_shipment
      raise Error::ErrorDestiny.new(reference.to_s) unless destiny == 'domicilio'
      raise Error::ErrorNotDestinyPayable.new(reference.to_s) if destiny == 'domicilio' && payable == true
      raise Error::ErrorNotCourierDestinyAvailable.new(reference.to_s) unless commune.available_for('shippify')

      true
    end
  end
end
