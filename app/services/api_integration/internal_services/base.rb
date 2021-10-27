module ApiIntegration
  module InternalServices
    class Base
      include ApiConnection

      BASE_URI = Rails.configuration.internal[:url]

      attr_accessor :errors
      attr_reader :headers

      def initialize(properties)
        @properties = properties || {}
        @errors = []
        headers
      end

      def index(_params)
        raise 'Method is not implemented'
      end

      def show(_id)
        raise 'Method is not implemented'
      end

      def create(_params)
        raise 'Method is not implemented'
      end

      def update(_id, _params)
        raise 'Method is not implemented'
      end

      private

      def default_user
        @default_user ||= User.unscoped.find_by(email: 'staff@shipit.cl')
      end

      def headers
        @headers = {
          'Accept' => 'application/vnd.internal.v1',
          'Content-Type' => 'application/json',
          'X-Shipit-Email' => @properties[:email] || default_user.try(:email),
          'X-Shipit-Access-Token' => @properties[:authentication_token] || default_user.try(:authentication_token)
        }
      end
    end
  end
end
