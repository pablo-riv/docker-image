module Calculator
  module Courier
    def couriers
      @attributes[:couriers].presence || @attributes[:courier_for_client].presence
    rescue StandardError => _e
      nil
    end

    def availables_by_commune(commune_id: origin)
      couriers_availables_by_communes = ::Commune.find_by(id: commune_id).try(:couriers_availables) || {}
      opit['couriers'].map { |object| inverse_courier(name: object.keys.first) if object[object.keys.first]['available'] }
                      .compact.uniq
                      .inject({}) { |object, courier| object.merge(courier => couriers_availables_by_communes[courier]) }
    end

    def availables_by_origin_and_destiny(origin_commune_id, destiny_commune_id)
      if company.backoffice_couriers_enabled?
        Coverages::Courier.new({ account: company.current_account }).availables_by_origin_and_destiny(1, origin_commune_id, destiny_commune_id)
      else
        {
          from: availables_by_commune,
          to: availables_by_commune(commune_id: destiny_commune_id)
        }
      end
    end

    def inverse_courier(name: '')
      case name
      when 'cxp' then 'chilexpress'
      when 'stk' then 'starken'
      when 'cc' then 'correoschile'
      when 'dhl' then 'dhl'
      when 'muvsmart' then 'muvsmart'
      when 'chileparcels' then 'chileparcels'
      when 'motopartner' then 'motopartner'
      when 'bluexpress' then 'bluexpress'
      when 'shippify' then 'shippify'
      end
    end
  end
end
