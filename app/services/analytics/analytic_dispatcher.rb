module Analytics
  class AnalyticDispatcher
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
      @object =
        case @properties[:model]
        when 'shipments' then Analytics::Shipment.new(@properties)
        when 'orders' then Analytics::Order.new(@properties)
        when 'supports' then Analytics::Support.new(@properties)
        when 'pickups' then Analytics::Pickup.new(@properties)
        end
    end

    def instance
      @object
    end
  end
end
