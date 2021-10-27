module ApiIntegration
  module InternalServices
    class Returns < Base
      def initialize(properties = nil)
        super(properties)
      end

      def pick_and_pack_process
        data = call(method: :post,
                    url: "#{BASE_URI}/returns/pick_and_pack_process",
                    headers: @headers)
        validate_response(data)
        { data: data }.with_indifferent_access
      end

      private

      def validate_response(data)
        return if data.is_a?(Array)

        error = data.dig('errors', 'detail')
        raise error if error.present?
      end
    end
  end
end
