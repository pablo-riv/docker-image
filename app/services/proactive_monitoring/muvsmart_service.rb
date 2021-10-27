module ProactiveMonitoring
  class MuvsmartService < Base

    attr_writer :engagement_rules

    def initialize(package, delivery_date)
      @organization_id = 360_066_274_133
      @engagement_rules = nil
      super(package, delivery_date, @organization_id)
    end
  end
end
