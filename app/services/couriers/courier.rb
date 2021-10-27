module Couriers
  class Courier
    attr_accessor :destiny, :payable, :reference, :commune_id

    def initialize(destiny, payable, reference, commune_id)
      @destiny = destiny
      @payable = payable
      @reference = reference
      @commune_id = commune_id
    end

    def destiny
      @destiny.try(:downcase) || 'domicilio'
    end

    def commune
      Commune.find(@commune_id)
    end

    def self.all
      %w(chilexpress starken dhl correoschile muvsmart chileparcels motopartner bluexpress shippify)
    end
  end
end
