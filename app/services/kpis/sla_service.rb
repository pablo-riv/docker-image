module Kpis
  class SlaService
    def initialize(object)
      @object = object
      @errors = []
    end

    def recalculate_sla(date_to = Date.current, from_package_id = nil)
      puts "\n==== STARTING SLA CALCULATION ===="
      last_package = Package.where(id: (from_package_id || last_package_calculated_id(date_to))).first
      puts "From last calculated KPI with package ID:#{last_package.try(:id) || 'N/A'}, to date: #{date_to.strftime('%Y/%m/%d')}"
      current_day_sla = Kpi.find_by(kpiable_type: 'Company', kpiable_id: company.id, kind: :sla, associated_date: date_to.to_date, entity_type: 'Package')
      packages_to_calculate = pending_packages_to_calculate(last_package, date_to)

      couriers.each do |courier|
        puts "\n === Calculating SLA for courier: #{courier} ==="
        previous_day_calculated_sla = Kpi.where(kpiable_type: 'Company', kpiable_id: company.id, kind: :sla, associated_date: (date_to - 1.day)..date_to, entity_type: 'Package', associated_courier: courier).first
        filtered_packages = filter_courier_packages(packages_to_calculate, courier)
        puts "PACKAGES TO CALCULATE: #{filtered_packages.size}\nPREVIOUS_DAY_CALCULATED: #{previous_day_calculated_sla.try(:value) || 0}"
        puts 'SLA mantained since there are no pending packages.' if filtered_packages.empty?
        save_sla(last_package_id: last_package.try(:id),
                 previous_sla: previous_day_calculated_sla,
                 pending_packages: filtered_packages,
                 current_sla: current_day_sla,
                 courier: courier,
                 date_to: date_to)
      end
    rescue => e
      puts "EXCEPTION: #{e.message}\nBACKTRACE: #{e.backtrace.first(5).join("\n")}".red.swap
    end

    private

    def calculate_weighted_sla(last_sla, last_packages_accumulated, new_sla, pending_packages_quantity)
      return new_sla if last_sla.nil? || last_sla == new_sla || last_packages_accumulated.zero?
      return last_sla unless pending_packages_quantity.positive?

      last_sla_proportion = last_sla / 100 * last_packages_accumulated
      new_sla_proportion = new_sla / 100 * pending_packages_quantity
      total_accumulated = last_packages_accumulated + pending_packages_quantity
      ((last_sla_proportion + new_sla_proportion) / total_accumulated * 100).to_i
    end

    def operational_sla(packages)
      puts '== Calculating operational SLA =='
      accomplished = packages.select(&:accomplishments).size
      unaccomplished = packages.reject(&:accomplishments).size
      puts "DATA_COUNT: #{packages.size}| ACC: #{accomplished}| UNACC: #{unaccomplished} | BOTH_ZERO: #{accomplished.zero? && unaccomplished.zero?}"
      return 0 if accomplished.zero? && unaccomplished.zero?
      result = (accomplished.to_f / (accomplished + unaccomplished) * 100).round(1)
      puts "SLA: #{result}%"
      result
    end

    def pending_packages_to_calculate(last_package, date_to = Date.current)
      return [] unless last_package.present?

      pending = last_package.updated_at.to_date <= date_to.to_date
      puts "There are no pending packages from the last kpi to #{date_to.strftime('%d/%m/%Y')}" unless pending
      return [] unless pending

      pending_packages =
        company.packages.left_outer_joins(:accomplishment)
               .select('packages.id, LOWER(packages.courier_for_client) AS courier_for_client, packages.created_at, packages.updated_at, accomplishments.delivery_accomplishment AS accomplishments')
               .where('packages.created_at > ? AND packages.created_at <= ? AND packages.status = 2', last_package.created_at, date_to.end_of_day)
               .order(created_at: :asc)
               .load
      return [] if pending_packages.empty?

      puts "==== Package from collection IDs ====\nFirst: #{pending_packages.try(:first).try(:id) || 'N/A'} with created_date #{pending_packages.try(:first).try(:created_at)}\nLast: #{pending_packages.try(:last).try(:id)} with updated_date #{pending_packages.try(:last).try(:created_at)}"
      puts "Pending packages: #{pending_packages.size}."
      pending_packages
    end

    def filter_courier_packages(packages, courier = 'shipit')
      return [] unless packages.present?
      return packages if courier == 'shipit'

      packages.where('LOWER(packages.courier_for_client) = ?', courier)
    end

    def save_sla(data)
      accumulated_quantity = data[:previous_sla].try(:entity_accumulated_quantity).to_i.positive? ? data[:previous_sla].entity_accumulated_quantity : 0
      new_sla = data[:pending_packages].empty? ? data[:previous_sla].try(:value) || 0 : operational_sla(data[:pending_packages])
      puts "Decided ID: #{data[:pending_packages].try(:last).try(:id) || data[:last_package_id]}"
      new_accumulated_quantity = accumulated_quantity + data[:pending_packages].size
      puts "New Accumulated packages: #{new_accumulated_quantity}"
      weighted_sla = calculate_weighted_sla(data[:previous_sla].try(:value), accumulated_quantity, new_sla, data[:pending_packages].size)
      puts "WEIGHTED SLA: #{weighted_sla}"
      if data[:current_sla].try(:associated_date).try(:to_date) == data[:date_to].to_date
        return puts 'No changes required' unless data[:pending_packages].size.positive? && new_sla != data[:current_sla].value
        puts 'Updating previous SLA associated with the same date.'
        data[:current_sla].update(value: weighted_sla,
                                  entity_last_checked_id: data[:pending_packages].try(:last).try(:id) || data[:last_package_id],
                                  entity_accumulated_quantity: new_accumulated_quantity)
      else
        puts 'Creating new SLA instance.'
        Kpi.create!(kpiable_type: 'Company',
                    kpiable_id: company.id,
                    kind: :sla,
                    aggregation: :day,
                    value: weighted_sla,
                    associated_date: data[:date_to].to_date,
                    associated_courier: data[:courier],
                    entity_type: 'Package',
                    entity_last_checked_id: data[:pending_packages].try(:last).try(:id) || data[:last_package_id],
                    entity_accumulated_quantity: new_accumulated_quantity)
      end
    rescue => e
      puts "EXCEPTION: #{e.message}\nBACKTRACE: #{e.backtrace.first(5).join("\n")}".red.swap
    end

    def last_package_calculated_id(date_to = Date.current)
      Kpi.last_calculated_package_id(kpiable_type: 'Company', kpiable_id: company.id, kind: :sla, entity_type: 'Package', date_to: date_to)
    end

    def company
      @object[:company]
    end

    def couriers
      %w(chilexpress starken muvsmart chileparcels motopartner bluexpress shipit) # dhl & correoschile were left out.
    end
  end
end
