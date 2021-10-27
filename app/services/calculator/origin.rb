module Calculator
  module Origin
    def origin
      raise unless @attributes[:origin_id].present?

      @attributes[:origin_id]
    rescue StandardError => _e
      ::Commune.find_by(name: 'LAS CONDES').try(:id)
    end
  end
end
