module Analytics
  module AnalyticInterface
    def charts
      raise 'Can not call abstract method'
    end

    def metrics
      raise 'Can not call abstract method'
    end

    def analize
      raise 'Can not call abstract method'
    end

    def percent
      raise 'Can not call abstract method'
    end

    def average
      raise 'Can not call abstract method'
    end

    def chart_serials
      raise 'Can not call abstract method'
    end

    def total_chart
      raise 'Can not call abstract method'
    end

    def sla_chart
      raise 'Can not call abstract method'
    end

    def cost_chart
      raise 'Can not call abstract method'
    end

    def calculate_chart
      raise 'Can not call abstract method'
    end

    def filter_serials
      raise 'Can not call abstract method'
    end
  end
end
