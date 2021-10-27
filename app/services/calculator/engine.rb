module Calculator
  class Engine
    def self.allowed_attributes
      base_parameters = %i[order_id length width height weight to_commune_id commune_id is_payable destiny courier_selected courier_for_client new_format algorithm algorithm_days type_of_service type_of_payment]
      multi_origin_parameters = [:rate_from, :origin_id, :destiny_id, :type_of_destiny, :type_of_service, :type_of_payment, :couriers, is_payable: [], type_of_service: [], type_of_payment: []]
      (base_parameters + multi_origin_parameters) - (base_parameters & multi_origin_parameters)
    end

    def self.calculate(attributes)
      checkout = filter_integration(rate_from: attributes[:rate_from],
                                    integration: attributes[:integration])
      @parcel = Parcel.new(attributes)
      return checkout_custom(parcel: @parcel, checkout: checkout) if checkout[:rates][:when_show_shipit_rate] == 'never'

      prices = Rate.new(rate: @parcel.calculate).process
      return checkout_custom(parcel: @parcel, checkout: checkout) if checkout[:rates][:when_show_shipit_rate] == 'with_no_rates' && prices.nil?
      raise 'No obtuvimos precios bajo los parametros enviados' if prices.nil?

      prices
    rescue Net::ReadTimeout => e
      return checkout_custom(parcel: @parcel, checkout: checkout, service_message: e.message) if checkout[:rates][:when_show_shipit_rate] == 'with_no_rates' && prices.nil?

      raise 'No obtuvimos precios bajo los parametros enviados line: 23'
    rescue => e
      return checkout_custom(parcel: @parcel, checkout: checkout, service_message: e.message) if checkout[:rates][:when_show_shipit_rate] == 'with_no_rates' && prices.nil?

      raise "No obtuvimos precios bajo los parametros enviados line: 27"
    end

    def self.checkout_custom(parcel: {}, checkout: {}, service_message: '')
      couriers_availables_to = parcel.availables_by_origin_and_destiny(parcel.origin, parcel.destiny)[:to].delete_if { |_key, value| value.empty? }
      raise 'No obtuvimos precios bajo la configuración disponible' if couriers_availables_to.empty?

      checkout_custom_response(commune: Commune.find_by(id: @parcel.destiny),
                               checkout: checkout,
                               company: @parcel.company,
                               service_message: service_message)
    end

    def self.filter_integration(rate_from: 'api', integration: {})
      raise if rate_from.downcase == 'api' || integration.keys.empty?

      integration[rate_from.to_sym][:checkout]
    rescue StandardError => _e
      { show_rate: true,
        rates: { when_show_shipit_rate: 'always' } }.with_indifferent_access
    end

    def self.checkout_custom_response(commune: {}, checkout: {}, company: {}, service_message: '')
      raise if commune.blank? || checkout.empty?

      price = checkout[:rates][:zones][commune.region.number.to_s]
      trigger_slack_message(company: company, commune: commune, price: price, service_message: service_message) if checkout[:rates][:when_show_shipit_rate] == 'with_no_rates'
      price = { courier: { name: checkout[:rates][:courier].try(:downcase) },
                original_name: checkout[:rates][:courier].try(:downcase),
                name: 'DIA HABIL SIGUIENTE',
                available_to_shipping: true,
                price: price,
                days: '' }
      { lower_price: price,
        prices: [price] }
    end

    def self.trigger_slack_message(company: {}, commune: {}, price: 0, service_message: '')
      Slack::CustomCheckout.new&.alert(message: "[#{Rails.env.upcase}]\nCliente: #{company.name} - #{company.id} cotizó y no obtuvo precio en su integración para la comuna #{commune.name} - precio: #{price}\nMensaje del servidor: #{service_message}")
    end
  end
end