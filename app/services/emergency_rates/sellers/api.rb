module EmergencyRates
  module Sellers
    module Api
      def post(url: '', headers: {}, body: {})
        response = HTTParty.post(url, body: body, headers: headers, verify: false, timeout: 90)
        { data: JSON.parse(response.read_body), code: response.code }
      rescue StandardError => e
        Rails.logger.error e
      end

      def get(url: '', headers: {}, query: {})
        response = HTTParty.get(url, headers: headers, query: query, verify: false, timeout: 90)
        { data: JSON.parse(response.read_body), code: response.code }
      end
    end
  end
end
