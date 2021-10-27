module Calculator
  module Destiny
    def destiny
      @attributes[:destiny_id]
    end

    def type_of_destiny
      @attributes[:type_of_destiny].presence.try(:downcase)
    rescue StandardError => _e
      'domicilio'
    end

    def type_of_payment
      @attributes[:type_of_payment].presence || @attributes[:is_payable].presence || false
    rescue StandardError => _e
      false
    end
  end
end
