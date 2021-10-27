module CuttingHours
  class Area < CuttingHours::CuttingHour
    def initialize(parameters)
      super(parameters)
    end

    def calculate_cutting_hour
      @hours_collection << model.cutting_hour.by_service(abbreviated)
      super
    end
  end
end
