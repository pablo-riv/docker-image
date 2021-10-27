module CuttingHours
  class CuttingHour
    include CuttingHours::Calculator

    attr_accessor :errors

    def initialize(properties = {})
      @properties = properties
      @hours_collection = hours_collection
      @errors = []
    end

    def datetime
      @properties[:datetime].presence || DateTime.current
    end

    def model
      @properties[:model].presence || ::DistributionCenter.default
    end

    def service
      @properties[:service]&.downcase.presence || 'pick_and_pack'
    end

    def hours_collection
      @properties[:hours_collection].presence || []
    end

    def reverse
      @properties[:reverse]
    end

    def current
      @properties[:current]
    end

    private

    def pick_and_pack?(temp_service = nil)
      temp_service ||= service
      %w[pick_and_pack pp].include?(temp_service)
    end

    def find_service
      model.try(:service) || abbreviated
    end
  end
end
