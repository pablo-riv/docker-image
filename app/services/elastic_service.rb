class ElasticService
  include HTTParty
  base_uri Rails.configuration.elastic_api_url

  def initialize(current_account)
    @headers = { 'Content-Type' => 'application/json',
                 'Accept' => 'application/vnd.shipit.v4',
                 'X-Shipit-Email' => current_account.email,
                 'X-Shipit-Access-Token' => current_account.authentication_token }
  end

  def addresses(query, page, per_page)
    response = self.class.get('/addresses', { headers: @headers, query: { query: query, page: page, per_page: per_page }, verify: false })
    response.success? ? response.dig('addresses', 'data') : {}
  end

  def branch_offices(query, page, per_page)
    response = self.class.get('/branch_offices', { headers: @headers, query: { query: query, page: page, per_page: per_page }, verify: false })
    response.success? ? response.dig('branch_offices', 'data') : {}
  end

  def companies(query, page, per_page)
    response = self.class.get('/companies', { headers: @headers, query: { query: query, page: page, per_page: per_page }, verify: false })
    response.success? ? response.dig('companies', 'data') : {}
  end

  def craftsmen(query, page, per_page)
    response = self.class.get('/craftsmen', { headers: @headers, query: { query: query, page: page, per_page: per_page }, verify: false })
    response.success? ? response.dig('craftsmen', 'data') : {}
  end

  def heroes(query, page, per_page)
    response = self.class.get('/heroes', { headers: @headers, query: { query: query, page: page, per_page: per_page }, verify: false })
    response.success? ? response.dig('heroes', 'data') : {}
  end

  def shipments(query, page, per_page)
    response = self.class.get('/shipments', { headers: @headers, query: { query: query, page: page, per_page: per_page }, verify: false })
    response.success? ? response.dig('shipments') : {}
  end

  def orders(query, page, per_page)
    response = self.class.get('/orders', { headers: @headers, query: { query: query, page: page, per_page: per_page }, verify: false })
    response.success? ? response.dig('orders', 'data') : {}
  end
end
