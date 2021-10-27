module EmergencyRates
  module Sellers
    class Woocommerce
      include Api

      def initialize(attributes)
        @seller = attributes[:seller]
        @seller_name = attributes[:seller].first[0]
        @setting = attributes[:setting]
        @account = attributes[:account]
        @webhook = attributes[:webhook]
        @url = url
        @headers = headers
      end

      def headers
        { 'Authorization' => "Basic #{@webhook['options']['authorization']['token']}",
          'Content-Type' => 'application/json' }
      end

      def url
        @webhook['url'].split('/orders/').push('/emergency_rates').join if @webhook['url'].present?
      end

      def upload_rate
        response = post(url: @url,
                        headers: @headers,
                        body: { configuration: @seller[@seller_name]['checkout'] }.to_json)
        puts "#{@seller_name} #{@setting.company_id}".green
        puts "Response: #{response}"
      end
    end
  end
end
