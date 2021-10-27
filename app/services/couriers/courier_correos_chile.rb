module Couriers
  class CourierCorreosChile < Couriers::Courier
    def initialize(destiny, payable, reference, commune_id)
      super(destiny, payable, reference, commune_id)
    end

    def valid_shipment
      raise Error::ErrorDestiny.new(reference.to_s) unless destiny == 'domicilio' || destiny == 'correoschile'
      raise Error::ErrorNotCourierDestinyAvailable.new(reference.to_s) unless commune.available_for('correschile')

      true
    end
  end
end
