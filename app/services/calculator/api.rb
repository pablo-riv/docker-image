module Calculator
  module Api
    def prices
      self.class.post('/api/prices', body: prices_params,
                                     headers: { 'Content-Type' => 'application/json',
                                                'Accept' => 'application/vnd.opit-v1' })
    end

    private

    def prices_params
      couriers_availables_by_coverage = availables_by_origin_and_destiny(origin, destiny)
      { couriers_availables_from: couriers_availables_by_coverage[:from],
        couriers_availables_to: couriers_availables_by_coverage[:to],
        length: length,
        width: width,
        height: height,
        weight: weight,
        is_payable: type_of_payment,
        destiny: type_of_destiny,
        algorithm: algorithm,
        algorithm_days: algorithm_days,
        commune_id: destiny,
        new_format: false }.to_json
    end
  end
end

