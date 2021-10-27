module Charges
  class Charge
    include Charges::Interface
    # TODO: REFACTOR THIS CLASS
    # TODO: CALCULATION CLASS
    # TODO: DECORATOR OR STRATEGY PATTERN TO RENDER DATA
    attr_accessor :properties, :errors

    def initialize(properties)
      @properties = properties
      @errors = []
    end

    def calculate
      eval(properties[:kind])
    end

    def yearly
      shipments_grouped = shipments.group_by { |p| p.created_at.strftime('%m/%Y') }.sort.reverse
      inventories_grouped = service == 'fulfillment' ? inventories.group_by { |c| c.created_at.strftime('%m/%Y') }.sort.reverse : []
      shipments_grouped.map do |date, data|
        total_returns_price = total_returns(data)
        shipping_price = total_shipping_price(data)
        overcharges = total_overcharges(data)
        service_price = total_service_price(date, data, inventories_grouped)
        plan = total_base(date)
        recurrent = total_recurrent(date)
        total_refunds = decorate_values(total_refunds(date) * -1)
        total_commercial_discounts = decorate_values(total_commercial_discounts(date) * -1)
        invoice = invoices.find { |i| i.emit_date.month == date[0..1].to_i }
        { date: date.to_date,
          service: service,
          state: invoice.try(:state).try(:presence) || 'without_state',
          service_price: service_price,
          shipping_price: decorate_values(shipping_price + total_returns_price),
          overcharges: decorate_values(overcharges),
          recurrent: recurrent,
          plan: decorate_values(plan),
          refunds: total_refunds + total_commercial_discounts,
          invoice: invoice_file(invoice),
          total: [service_price, shipping_price, total_returns_price, overcharges, plan, total_refunds, total_commercial_discounts, recurrent].sum.round }
      end
    end

    def details
      eval(properties[:specific])
    rescue => e
      Slack::Ti.new({}, {}).alert('', "HANDLE ERROR AT LINE: 48 Charges::Charge#details\nERROR: #{e.message}\nBUGTRACE: #{e.backtrace.first}")
      []
    end

    def generate_report(charges: [], name: '')
      report = Report.new(charges: charges,
                          name: name,
                          service: (service == 'pick_and_pack' ? 'Retiro' : 'Bodegaje'))
      report.make
    end

    private

    def total_service_price(date, shipments_data, inventories_grouped)
      return total_pick_and_pack(date, shipments_data) if service == 'pick_and_pack'

      inventories_data = inventories_grouped.map { |grouped_date, data| next unless grouped_date == date; data }.compact
      total_fulfillment(date, inventories_data.flatten)
    end

    def decorate_values(value)
      (value.presence || 0).round
    end

    def total_shipping_price(data)
      data.reject(&:is_returned).pluck(:shipping_price).map(&:to_f).sum
    end

    def total_shipments(data)
      return 0 unless data.present?

      data.reject(&:is_returned).pluck(:total).map(&:to_f).sum
    end

    def total_discounts(data)
      return 0 unless data.present?

      data.reject(&:is_returned).pluck(:discount_amount).map(&:to_f).sum
    end

    def total_overcharges(data)
      data.reject(&:is_returned).pluck(:overcharge).map(&:to_f).sum + insurance_prices(data)
    end

    def insurance_prices(data)
      data.map { |shipment| shipment.insurance_total_price.to_f if shipment.insurance_total_price.try(:positive?) && shipment.insurance_extra }.compact.sum.round.to_i
    end

    def total_returns(data)
      data.select(&:is_returned).pluck(:total).map(&:to_f).sum
    end

    def total_premium(date)
      calculate_total(filter(premium, date))
    end

    def total_recurrent(date)
      calculate_total(filter(recurrent, date))
    end

    def total_refunds(date)
      calculate_total(filter(refunds, date))
    end

    def total_commercial_discounts(date)
      calculate_total(filter(commercial_discounts, date))
    end

    def total_pick_and_pack(date, data)
      monthly_fines = calculate_total(filter(fines, date))
      monthly_parkings = calculate_total(filter(parkings, date))
      material_extra = data.pluck(:material_extra).map(&:to_f).sum

      [monthly_fines, monthly_parkings, material_extra].sum
    end

    def total_fulfillment(date, data)
      %w[in out stock others].inject(0) { |total, type| total_amount_of(type, date, data) + total }.round
    end

    def total_amount_of(category, date, data, format = '%m/%Y')
      data.select { |f| f.date.strftime(format) == date }
          .map { |c| sum_amounts(c.details[category]) }.sum
    end

    def sum_amounts(details)
      details.map { |c| c['amount'].try(:to_f) }.compact.sum
    end

    def total_base(date)
      monthly_subscription = subscriptions.find { |subscription| subscription.created_at.strftime('%m/%Y') == date }
      if monthly_subscription.present?
        monthly_subscription.prices['floor_price'].to_f * select_tax_by_month(date)
      else
        return 0.0 if service == 'fulfillment'

        base_charges.find { |bc| bc.date.strftime('%m/%Y') == date }.try(:base_charge).try(:to_f) || 0
      end
    end

    def period
      @properties[:period]
    end

    def service
      @properties[:service]
    end

    def shipments
      @properties[:data][:shipments]
    end

    def overcharges
      @properties[:data][:overcharges]
    end

    def insurances
      @properties[:data][:insurances]
    end

    def returns
      @properties[:data][:returns]
    end

    def inventories
      @properties[:data][:inventories]
    end

    def base_charges
      @properties[:data][:base_charge]
    end

    def fines
      @properties[:data][:fines]
    end

    def parkings
      @properties[:data][:parkings]
    end

    def refunds
      @properties[:data][:refunds]
    end

    def commercial_discounts
      @properties[:data][:commercial_discounts]
    end

    def paid_by_shipit
      @properties[:data][:paid_by_shipit]
    end

    def indemnify
      @properties[:data][:indemnify]
    end

    def premium
      @properties[:data][:premium]
    end

    def recurrent
      @properties[:data][:recurrent]
    end

    def subscriptions
      @properties[:data][:subscriptions]
    end

    def taxs
      @properties[:data][:taxs]
    end

    def invoices
      @properties[:data][:invoices]
    end

    protected

    def select_tax_by_month(date)
      monthly_taxs = taxs.find { |tax| tax.created_at.strftime('%m/%Y') == date }
      monthly_taxs.try(:value) || 1
    end

    def filter(data, date)
      return [] unless data.present?

      data.select { |f| f.date.strftime('%m/%Y') == date }
    end

    def calculate_total(data)
      data.pluck(:amount).map(&:to_f).sum
    end

    %w[in_fulfillment out_fulfillment stock_fulfillment others_fulfillment].each do |method_name|
      define_method method_name.to_sym do
        data = []
        @properties[:data][method_name.to_sym].each do |fulfillmen_charge|
          fulfillmen_charge.details[method_name.split('_').first].each do |fulfillmen_specific|
            data << HashWithIndifferentAccess.new(fulfillmen_specific.merge(date: fulfillmen_charge.date))
          end
        end
        data.sort_by { |charge| charge[:date] }.reverse
      end
    end

    def invoice_file(invoice = {})
      invoice.files['pdf']
    rescue => e
      Rails.logger.info "#{e.message}".red.swap
      ''
    end
  end
end
