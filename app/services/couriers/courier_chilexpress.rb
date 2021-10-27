module Couriers
  class CourierChilexpress < Couriers::Courier
    def initialize(destiny, payable, reference, commune_id)
      super(destiny, payable, reference, commune_id)
    end

    def valid_shipment
      raise Error::ErrorDestiny.new(reference.to_s) unless %W[domicilio sucursal chilexpress].include?(destiny.downcase)
      raise Error::ErrorNotDestinyPayable.new(reference.to_s) if payable == true
      raise Error::ErrorNotCourierDestinyAvailable.new(reference.to_s) unless commune.available_for('chilexpress')

      true
    end
  end
end
