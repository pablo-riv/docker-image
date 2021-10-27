module Slack
  class Ops < Slack::Ti
    attr_accessor :package

    def initialize(package, company, team = nil)
      super(package, company, team)
    end

    def alert(error = nil, message = nil, channel = '#ops_alert')
      super
    end
  end
end
