module Analytics
  class AnalyticGenerator
    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def metrics
      period = Analytics::Period.new(period: @properties[:period])
      analytic = RecursiveOpenStruct.new
      models.each do |model|
        data = Analytics::Collect.new(model: model, periods: period.periods, company: @properties[:company]).exec
        dispatcher = Analytics::AnalyticDispatcher.new(days: period.period,
                                                       model: model,
                                                       periods: period.periods,
                                                       current: data[:current],
                                                       last: data[:last],
                                                       total: data[:total]).instance
        raise 'modelo enviado no permitido' if dispatcher.nil?

        analytic[model] = dispatcher.metrics[model]
      end

      analytic
    end

    def operational_metrics
      period = Analytics::Period.new(period: @properties[:period])
      analytic = RecursiveOpenStruct.new

      models(%w(shipments supports)).each do |model|
        data = Analytics::Collect.new(model: model, periods: period.periods, company: @properties[:company]).exec
        dispatcher = Analytics::AnalyticDispatcher.new(days: period.period,
                                                       model: model,
                                                       periods: period.periods,
                                                       current: data[:current],
                                                       last: data[:last],
                                                       company: @properties[:company]).instance
        analytic[model] = dispatcher.operational_metrics[model]
      end

      analytic
    end

    def pickups
      period = Analytics::Period.new(period: 1)
      data = Analytics::Collect.new(model: 'pickups', periods: period.periods, company: @properties[:company]).exec
      dispatcher = Analytics::AnalyticDispatcher.new(model: 'pickups',
                                                     total: data[:total]).instance
      RecursiveOpenStruct.new(dispatcher.metrics)
    end

    def charts
      period = Analytics::Period.new(period: @properties[:period])
      data = Analytics::Collect.new(model: @properties[:model], periods: period.periods, company: @properties[:company]).exec
      dispatcher = Analytics::AnalyticDispatcher.new(days: period.period,
                                                     model: @properties[:model],
                                                     periods: period.periods,
                                                     current: data[:current],
                                                     last: data[:last],
                                                     total: data[:total]).instance
      if kind == 'sell_cost'
        shipments = Analytics::Collect.new(model: 'shipments', periods: period.periods, company: @properties[:company]).exec
        RecursiveOpenStruct.new(dispatcher.sell_cost_chart(shipments, data))
      else
        RecursiveOpenStruct.new(dispatcher.send("#{kind}_chart"))
      end
    end

    def models(default = %w(shipments orders))
      return default unless @properties[:models].present?

      @properties[:models].split(',').map(&:strip)
    end

    def kind
      return 'total' unless @properties[:kind].present?

      @properties[:kind]
    end
  end
end
