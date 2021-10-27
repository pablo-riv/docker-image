module CuttingHours
  class Company < CuttingHours::CuttingHour
    def initialize(properties)
      super(properties)
    end

    def calculate_cutting_hour
      @hours_collection << model.cutting_hour.by_service(abbreviated)
      @hours_collection << model.address.commune.cutting_hour.by_service(abbreviated) if relations?
      super
    end

    private

    def relations?
      [model.address, model.address&.commune, model.address&.commune&.cutting_hours].all?(&:present?)
    end
  end
end
