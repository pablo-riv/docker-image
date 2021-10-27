module EmergencyRates
  module Sellers
    class Shopify
      include Api

      def initialize(attributes)
        @seller = attributes[:seller]
        @seller_name = attributes[:seller].first[0]
        @setting = attributes[:setting]
        @account = attributes[:account]
        @url = Rails.configuration.shopify_app_url
        @headers = headers
      end

      def headers
        { 'X-Shipit-Email' => @account.email,
          'X-Shipit-Access-Token' => @account.authentication_token,
          'Content-Type' => 'application/json' }
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
