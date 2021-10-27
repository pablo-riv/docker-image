module ProactiveMonitoring
  class MotopartnerService < Base

    attr_writer :engagement_rules

    def initialize(package, delivery_date)
      @organization_id = 368_057_518_813
      @engagement_rules = nil
      super(package, delivery_date, @organization_id)
    end
  end
end
