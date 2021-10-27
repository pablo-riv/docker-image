module CuttingHours
  class BranchOffice < CuttingHours::CuttingHour
    def initialize(properties)
      super(properties)
    end

    def calculate_cutting_hour
      @hours_collection << model.cutting_hour.by_service(abbreviated)
      @hours_collection << model.address.commune&.cutting_hour&.by_service(abbreviated) if relations?
      @hours_collection << model.area&.cutting_hour&.by_service(abbreviated) if pick_and_pack? && model.area.present?
      super
    end

    private

    def relations?
      [model.address, model.address&.commune, model.address&.commune&.cutting_hour].all?(&:present?) && pick_and_pack?
    end
  end
end
