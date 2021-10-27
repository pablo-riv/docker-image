module CuttingHours
  class Generator
    attr_accessor :properties, :errors

    def initialize(properties = {})
      @properties = properties
      @instance = instance
      @errors = []
    end

    def calculate_cutting_hour
      @instance.calculate_cutting_hour
    end

    def calculate_days
      @instance.calculate_days
    end

    private

    def instance
      Dispatcher.new(@properties).instance
    end
  end
end
