module Zendesk
  class CourierInfo
    def initialize(courier_name)
      @courier_name = courier_name
    end

    def courier_data
      data
    end

    private

    attr_reader :courier_name

    def valid_courier_name?
      couriers_symbol.include?(courier_name)
    end

    def couriers_symbol
      CourierOperationalInformation.by_kind.map { |info| info.courier.symbol }.compact
    end

    def data
      validate

      courier = Courier.find_by(symbol: courier_name)
      courier_data = courier.courier_operational_informations.unique_by_kind
      validate_fields(courier_data)

      data_struct(courier_data)
    rescue ArgumentError, NoMethodError => e
      Rails.logger.debug { "#{e.message}".red.swap }
      false
    end

    def validate
      message = I18n.t('activerecord.attributes.zendesk.ticket.proactive_monitoring.bad_attribute_courier')
      raise ArgumentError.new(message) unless valid_courier_name?
    end

    def validate_fields(courier_data)
      methods = %i[main_email greeting zendesk_id]
      errors =  translations.map.with_index do |translation, index|
        ArgumentError.new(translation) unless courier_data.try(methods[index]).presence
      end
      errors.compact!
      raise errors.pop if errors.present?

      true
    end

    def translations
      %w[invalid_email invalid_agent invalid_requester].map do |translation|
        I18n.t("activerecord.attributes.zendesk.ticket.proactive_monitoring.#{translation}")
      end
    end

    def data_struct(courier_data)
      email = courier_data.main_email
      {
        email: [email],
        agent_name: courier_data.greeting,
        requester_id: courier_data.zendesk_id
      }
    end
  end
end
