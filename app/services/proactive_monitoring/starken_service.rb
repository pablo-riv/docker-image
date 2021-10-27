module ProactiveMonitoring
  class StarkenService < Base

    attr_writer :engagement_rules

    def initialize(package, delivery_date)
      @organitzation_id = 360_017_099_074
      @engagement_rules = nil
      super(package, delivery_date + 1.days, @organitzation_id) # Estimated delay between shipit and courier deadline
    end
  end
end
