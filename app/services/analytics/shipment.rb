module Analytics
  class Shipment < Analytic
    CHARTS = %w(cost total sla).freeze
    PENDING_ACTION_STATUS = %w(incomplete_address unexisting_address reused_by_destinatary unkown_destinatary unreachable_destiny failed_by_retired).freeze
    LOSS_STATUS = %w(strayed damaged).freeze
    RETURNED_STATUS = %w(at_shipit returned).freeze
    NEXT_BUSINESS_DAY = 1.business_day.after(Date.current)

    def initialize(properties)
      super(properties)
    end

    CHARTS.each do |chart|
      define_method "#{chart}_chart".to_sym do
        public_send("#{chart}_serial")
      end
    end

    def metrics
      current_cost = cost(current)
      last_cost = cost(last)
      RecursiveOpenStruct.new(shipments: { total: { current: current.size,
                                                    last: last.size,
                                                    percent: percent(current.size, last.size),
                                                    total: total.size },
                                           cost: { current: current_cost,
                                                   last: last_cost,
                                                   total: cost(total),
                                                   average: average(cost(total), total.size),
                                                   percent: percent(current_cost, last_cost) },
                                           couriers: couriers })
    end

    def operational_metrics(shipments = {})
      indicators = %w(pending_action loss returned delayed)
      ratios = %w(delayed_average_days accomplished_sla)
      shipments.merge!(metric_structure('indicator', indicators))
      shipments.merge!(metric_structure('ratio', ratios))
      RecursiveOpenStruct.new(shipments: shipments)
    end

    def metric_structure(type = nil, data = [], draft = {})
      data.each do |metric|
        metric_hash = send("#{type.try(:downcase)}_structure", metric)
        draft.merge!(metric_hash)
      end
      { type.pluralize(2).to_sym => draft }
    end

    def indicator_structure(indicator = nil, draft = {})
      current_status = status_indicator(current, indicator.to_s)
      draft[:current] = current_status[:quantity]
      draft[:percent] = percent(current_status[:quantity], status_indicator(last, indicator.to_s)[:quantity])
      draft[:ids] = current_status[:ids]
      { indicator.to_sym => draft }
    end

    def ratio_structure(ratio = nil, draft = {})
      draft[:current] = send(ratio, current)
      draft[:last] = send(ratio, last)
      draft[:percent] = percent(draft[:current], draft[:last])
      { ratio.to_sym => draft }
    end

    def cost(data = [])
      return 0 if data.size.zero?

      data.map(&:total_price).map(&:to_f).sum
    end

    def status_indicator(data = [], status = nil, default = { quantity: 0, ids: [] })
      return default if data.empty? || status.nil?

      valid_shipments = data.reject { |shipment| shipment.sub_status == 'delivered' }

      case status
      when 'delayed' then check_delayed(valid_shipments)
      else check_status(valid_shipments, status)
      end
    end

    def check_delayed(data = [], default = { quantity: 0, ids: [] })
      return default if data.empty?

      delayed_shipments =
        data.select do |shipment|
          next if shipment.is_sandbox || shipment.reference.downcase.include?('test')

          promised_delivery_date = shipment.delivery_time.to_i.business_days.after(shipment.created_at).to_date
          promised_delivery_date <= NEXT_BUSINESS_DAY
        end
      Rails.logger.info "Delayed result:#{{ quantity: delayed_shipments.size || 0, ids: delayed_shipments.pluck(:id) }}".red
      { quantity: delayed_shipments.size, ids: delayed_shipments.pluck(:id) }
    end

    def check_status(data = [], status = nil, default = { quantity: 0, ids: [] })
      return default if data.empty? || status.nil?

      shipments = data.select do |shipment|
        next if shipment.is_sandbox || shipment.reference.downcase.include?('test')

        Object.const_get("Analytics::Shipment::#{status.upcase}_STATUS").include?(shipment.sub_status.to_s)
      end
      Rails.logger.info "Status #{status} | Result:#{{ quantity: shipments.size || 0, ids: shipments.pluck(:id) }}".red
      { quantity: shipments.size, ids: shipments.pluck(:id) }
    end

    def delayed_average_days(data = [])
      return 0 if data.empty?

      days_results =
        data.map do |shipment|
          promised_delivery_date = shipment.delivery_time.to_i.business_days.after(shipment.created_at).to_date
          behind_schedule = (promised_delivery_date <= NEXT_BUSINESS_DAY)
          next unless behind_schedule

          (NEXT_BUSINESS_DAY - promised_delivery_date).to_i
        end
      return 0 if days_results.compact.empty?

      days_results.compact.sum / days_results.size
    end

    def couriers
      current.select { |data| data.courier_for_client.present? }
             .group_by { |data| data.courier_for_client.try(:downcase) }
             .map { |courier, data| { name: courier, total: data.size, sla: calculate_sla(data) } }
    end

    def calculate_sla(data = [])
      accomplished = data.select(&:accomplishments).size
      unaccomplished = data.reject(&:accomplishments).size
      return '-' if accomplished.zero? && unaccomplished.zero?

      "#{number_with_delimiter((accomplished.to_f / (accomplished + unaccomplished) * 100).round(1))} %"
    end

    def accomplished_sla(data = [])
      selected_company_id = company_id
      last_kpi = Kpi.where(kpiable_type: 'Company', kpiable_id: selected_company_id, kind: :sla, associated_courier: 'shipit').try(:last)
      return (last_kpi.try(:value) || 0) unless data.size.positive?

      date_selected = data.try(:last).try(:created_at).try(:to_date) || Date.current
      daily_sla(date_selected, selected_company_id, 'shipit')
    end

    def daily_sla(date = Date.current, company_id = nil, courier_selected = 'shipit')
      kpi = Kpi.where(kpiable_type: 'Company', kpiable_id: company_id, kind: :sla, associated_courier: courier_selected, associated_date: date.to_date.beginning_of_day).try(:first)

      return 0 unless kpi.present?

      kpi.value
    end

    def global_sla(date = Date.current)
      Kpi.global_sla('shipit', date.to_date)
    end

    def company_id
      properties[:company].id
    end

    def total_serial
      chart_serials
    end

    def cost_serial
      chart_serials('cost')
    end

    def sla_serial
      chart_serials('sla')
    end
  end
end
