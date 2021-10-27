module Charges
  module Interface
    def calculate_extras
      raise "can't call abstract method"
    end

    def calculate_overcharge
      raise "can't call abstract method"
    end

    def calculate_shipments
      raise "can't call abstract method"
    end

    def calculate_base
      raise "can't call abstract method"
    end

    def calculate_total
      raise "can't call abstract method"
    end
  end
end
