module Analytics
  class Support < Analytic
    CHARTS = %w[total].freeze
    def initialize(properties)
      super(properties)
    end

    CHARTS.each do |chart|
      define_method "#{chart}_chart".to_sym do
        public_send("#{chart}_serial")
      end
    end

    def operational_metrics
      current_awaiting_client = status_indicator(current, 'pending')
      current_awaiting_customer_support = status_indicator(current, 'open')
      current_first_resolution_time = average_ratio(current, 'first_resolution_time_in_minutes_business')
      last_first_resolution_time = average_ratio(last, 'first_resolution_time_in_minutes_business')
      current_reply_time = average_ratio(current, 'reply_time_in_minutes_business')
      last_reply_time = average_ratio(last, 'reply_time_in_minutes_business')
      RecursiveOpenStruct.new(
        supports: {
          indicators: {
            awaiting_client: {
              current: current_awaiting_client[:quantity],
              ids: current_awaiting_client[:ids]
            },
            awaiting_customer_support: {
              current: current_awaiting_customer_support[:quantity],
              ids: current_awaiting_customer_support[:ids]
            }
          },
          ratios: {
            first_response_average_minutes: {
              current: current_first_resolution_time,
              last: last_first_resolution_time,
              percent: percent(current_first_resolution_time, last_first_resolution_time)
            },
            solved_average_minutes: {
              current: current_reply_time,
              last: last_reply_time,
              percent: percent(current_reply_time, last_reply_time)
            }
          }
        }
      )
    end

    def status_indicator(data = [], status = nil)
      default = { quantity: 0, ids: [] }
      return default if data.empty? || status.nil?

      supports = data.select { |support| support.status == status.to_s }
      { quantity: supports.size, ids: supports.pluck(:id).compact }
    end

    def average_ratio(data = [], type = nil)
      return 0 if data.empty? || type.nil?

      valid_metrics = data.map { |s| s.metrics[type.to_s] }.compact
      return 0 if valid_metrics.empty?

      sum = valid_metrics.sum.to_f
      (sum / valid_metrics.size).to_i
    end
  end
end
