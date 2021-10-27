module Analytics
  class Analytic
    include ActionView::Helpers::NumberHelper
    include AnalyticInterface

    attr_accessor :properties, :errors
    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def current
      @properties[:current]
    end

    def last
      @properties[:last]
    end

    def total
      @properties[:total]
    end

    def days
      @properties[:days]
    end

    def periods
      @properties[:periods]
    end

    def percent(current = 0.0, last = 0.0)
      last = last.to_f
      current = current.to_f
      return '0 %' if current == last
      return '100 %' if last.zero?

      "#{'+' if current > last}#{number_with_delimiter(((current - last) / last * 100).round(1))} %"
    end

    def average(amount, total)
      return 0 if total.zero?

      amount / total
    end

    def chart_serials(calculation = 'total', current_acc = 0, last_acc = 0)
      if calculation == 'sla'
        company_id = associated_company_id
        (0..days).map do |day|
          date = (periods.current.from + day.days).to_date
          { name: day,
            global: calculate_chart(nil, 'global_sla', nil, date),
            personal: calculate_chart(nil, 'daily_sla', company_id, date) }
        end
      else
        (0..days).map do |day|
          { name: day,
            last: (last_acc += calculate_chart(filter_serials(last, (periods.last.from + day.days)), calculation)),
            current: (current_acc += calculate_chart(filter_serials(current, (periods.current.from + day.days)), calculation)) }
        end
      end
    end

    def filter_serials(arry, date)
      arry.select do |data|
        data.created_at.to_date == date.to_date
      end
    end

    def calculate_chart(serial, calculation, company_id = nil, date = Date.current, courier = 'shipit')
      case calculation
      when 'total' then serial.size
      when 'cost' then serial.pluck(:total_price).map(&:to_f).sum
      when 'sells' then sum_sells(serial)
      when 'daily_sla' then daily_sla(date, company_id, courier)
      when 'global_sla' then global_sla(date)
      else
        0
      end
    rescue StandardError => e
      Slack::Ti.new({}, {}).alert('', "HANDLE ERROR AT LINE: 82 Analytics#calculate_chart\nERROR: #{e.message}\nBUGTRACE: #{e.backtrace.first}")
      0
    end

    def associated_company_id
      return if total.size.zero?

      BranchOffice.find(total.first.branch_office_id).company_id
    end
  end
end
