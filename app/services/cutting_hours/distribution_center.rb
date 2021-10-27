module CuttingHours
  class DistributionCenter < CuttingHours::CuttingHour
    def initialize(properties)
      super(properties)
    end

    def calculate_cutting_hour
      super
    end
  end
end
