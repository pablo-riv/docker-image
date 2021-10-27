module Coverages
  class Courier
    def initialize(attributes)
      @account = attributes[:account]
    end

    def availables_by_origin_and_destiny(country_id, origin_commune_id, destiny_commune_id)
      couriers = { from: {}, to: {} }
      return couriers unless [@account, origin_commune_id, destiny_commune_id].all?(&:present?)

      params = {
        country_id: country_id,
        origin_commune_id: origin_commune_id,
        destiny_commune_id: destiny_commune_id
      }
      coverages = PricesService::Coverages.new(@account).coverages(params)
      raise coverages[:errors][:detail] if coverages[:errors].present?

      coverages[:data].each do |coverage|
        courier_name = coverage[:courier][:name].downcase
        unless couriers[:from].key?(courier_name)
          couriers[:from][courier_name] = coverage[:origin][:commune_name_for_courier].presence ||
                                          coverage[:origin][:commune_name]
        end
        unless couriers[:to].key?(courier_name)
          couriers[:to][courier_name] = coverage[:destiny][:commune_name_for_courier].presence ||
                                        coverage[:destiny][:commune_name]
        end
      end
      couriers
    rescue StandardError => e
      Rails.logger.info { "#{e.message}\n#{e.backtrace}".red.swap }
      { from: {}, to: {} }
    end
  end
end
