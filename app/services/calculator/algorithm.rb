module Calculator
  module Algorithm
    def algorithm
      @attributes[:algorithm].presence || opit['algorithm'].presence
    rescue StandardError => _e
      1
    end

    def algorithm_days
      @attributes[:algorithm_days].presence || opit['algorithm_days'].presence
    rescue StandardError => _e
      0
    end
  end
end
