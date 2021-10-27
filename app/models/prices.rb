class Prices
  include HTTParty
  base_uri Rails.configuration.prices_url

  def initialize(account)
    @headers = { 'Content-Type' => 'application/json',
                 'Accept' => 'application/vnd.shipit.v4',
                 'X-Shipit-Email' => account.email,
                 'X-Shipit-Access-Token' => account.authentication_token }
  end

  def courier_branch_offices(courier_id: nil)
    result = self.class.get("/couriers/#{courier_id}/couriers_branch_offices", { headers: @headers, verify: false })
    raise 'Error' unless (200..204).cover?(result.code)

    result
  rescue => e
    puts e.message
    []
  end

  def couriers
    result = self.class.get('/couriers', { headers: @headers, verify: false })
    raise 'Error' unless (200..204).cover?(result.code)

    result
  rescue => e
    puts e.message
    []
  end

  def branch_offices
    result = self.class.get('/couriers_branch_offices', { headers: @headers, verify: false })
    raise 'Error' unless (200..204).cover?(result.code)

    result
  rescue => e
    puts e.message
    []
  end

  def courier_destinies(courier_id: nil)
    raise 'Error' if courier_id.zero?

    result = self.class.get("/couriers/#{courier_id}/destinies", headers: @headers)
    raise 'Error' unless (200..204).cover?(result.code)

    result
  rescue => e
    puts e.message
    []
  end

  def search_destinies(courier_id: nil, commune_id: nil, payable: nil, type_of_destiny: '')
    result = self.class.get('/destinies/search', { headers: @headers,
                                                   query: { courier_id: courier_id || '',
                                                            commune_id: commune_id,
                                                            payable: payable,
                                                            type_of_destiny: type_of_destiny }.with_indifferent_access,
                                                   verify: false })
    raise 'Error' unless (200..204).cover?(result.code)

    result
  rescue => e
    puts e.message
    []
  end

  def destiny(id: 0)
    raise 'Error' if id.zero?

    result = self.class.get("/destinies/#{id}", { headers: @headers, verify: false })
    raise 'Error' unless (200..204).cover?(result.code)

    result
  rescue => e
    puts e.message
    {}
  end
end
