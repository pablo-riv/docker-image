module CuttingHours
  class Commune < CuttingHours::CuttingHour
    def initialize(properties)
      super(properties)
    end

    def calculate_cutting_hour
      @hours_collection << model.cutting_hour.by_service(abbreviated)
      super
    end
  end
end
