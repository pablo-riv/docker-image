module Analytics
  module Error
    class AnalyticError < ::StandardError; end

    class NoImplementedMethod < AnalyticError; end
  end
end
