module Charges
  class Dispatcher
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
      @object =
        case @properties[:service]
        when 'pick_and_pack' then Charges::PickAndPack.new(@properties)
        when 'fulfillment' then Charges::Fulfillment.new(@properties)
        end
    end

    def instance
      @object
    end
  end
end
