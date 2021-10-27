module CuttingHours
  class Package < CuttingHours::CuttingHour
    def initialize(properties)
      super(properties)
    end

    def calculate_cutting_hour
      branch_office = model.branch_office
      @hours_collection << branch_office.cutting_hour.by_service(abbreviated)
      @hours_collection << branch_office.address.commune.cutting_hour.by_service(abbreviated) if relations?(branch_office)
      @hours_collection << branch_office.area.cutting_hour.by_service(abbreviated) if pick_and_pack?
      super
    end

    private

    def relations?(branch_office)
      [branch_office.address, branch_office.address&.commune, branch_office.address&.commune&.cutting_hours].all?(&:present?) && pick_and_pack?(find_service)
    end
  end
end
