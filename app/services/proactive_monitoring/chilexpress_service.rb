module ProactiveMonitoring
  class ChilexpressService < Base

    attr_writer :engagement_rules

    def initialize(package, delivery_date)
      @organitzation_id = 360_017_095_873
      @engagement_rules = nil
      super(package, delivery_date, @organitzation_id)
    end
  end
end
