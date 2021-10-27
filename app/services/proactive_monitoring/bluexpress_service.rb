module ProactiveMonitoring
  class BluexpressService < Base

    attr_writer :engagement_rules

    def initialize(package, delivery_date)
      @organitzation_id = 370_295_694_113
      @engagement_rules = nil
      super(package, delivery_date, @organitzation_id)
    end
  end
end
