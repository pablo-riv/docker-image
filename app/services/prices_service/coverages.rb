module PricesService
  class Coverages
    include ApiConnection
    PRICES_URL = Rails.configuration.prices_url

    def initialize(user)
      access_type = user.class.name.downcase
      @headers = { 'Content-Type' => 'application/json',
                   'Accept' => 'application/vnd.shipit.v4',
                   'X-Shipit-Access-Type' => access_type,
                   'X-Shipit-Email' => user.email,
                   'X-Shipit-Access-Token' => user.authentication_token }
    end

    def coverages(params)
      data = call(
        method: :get,
        url: "#{PRICES_URL}/coverages",
        query: params,
        headers: @headers)
      { data: data, total: data.size }.try(:with_indifferent_access)
    end
  end
end
