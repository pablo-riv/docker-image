module Coverages
  class Commune
    def initialize(attributes)
      @account = attributes[:account]
      @commune = attributes[:commune]
    end

    def available_by_origin_and_courier_name?(country_id, origin_commune_id, courier_name)
      return false unless [@account, origin_commune_id, @commune, courier_name].all?(&:present?)

      if @account.current_company.backoffice_couriers_enabled?
        couriers_availables = Coverages::Courier.new({ account: @account })
                                                .availables_by_origin_and_destiny(country_id,
                                                                                  origin_commune_id,
                                                                                  @commune.id)
        couriers_availables[:to][courier_name].blank? ? false : true
      else
        @commune.available_for(courier_name)
      end
    rescue StandardError => e
      Rails.logger.info { "#{e.message}\n#{e.backtrace}".red.swap }
      false
    end
  end
end

