module CuttingHours
  class Dispatcher
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
      @object =
        case @properties[:model].class.name.downcase
        when 'area' then CuttingHours::Area.new(@properties)
        when 'branchoffice' then CuttingHours::BranchOffice.new(@properties)
        when 'company' then CuttingHours::Company.new(@properties)
        when 'commune' then CuttingHours::Commune.new(@properties)
        when 'package' then CuttingHours::Package.new(@properties)
        when 'pickandpack' then CuttingHours::PickAndPack.new(@properties)
        else CuttingHours::DistributionCenter.new(@properties)
        end
    end

    def instance
      @object
    end
  end
end
