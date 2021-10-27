class BooticService
  include HTTParty
  def initialize
    @headers = { 'Accept' => 'application/json',
                 'Content-Type' => 'application/json',
                 'X-OAuth-Scopes' => 'admin' }
    @user_agent = "[BooticClient v#{VERSION}] Ruby-#{RUBY_VERSION} - #{RUBY_PLATFORM}"
    self.class.base_uri 'https://api.bootic.net/v1'
  end

  def order_status(order, status)
    token = Setting.fullit(order.company_id).configuration['fullit']['sellers'].find { |s| s.keys.first == 'bootic' }['bootic']['access_token']
    raise 'No tiene token de acceso registrado' if token.blank?
    res = self.class.put("/shops/#{order.shop_id}/orders/#{order.code}",
                          headers: @headers.merge({ 'User-Agent' => @user_agent, 'Authorization' => "Bearer #{token}" }),
                          query: {},
                          body: { status: status }.to_json)
    raise "This order #{res['_embedded']['errors'].first['messages'].first}" if res['_class'].first == 'errors'
    order.update_attributes(status: res['status'])
  end

  def load_tracking(order, tracking, courier)
    token = Setting.fullit(order.company_id).configuration['fullit']['sellers'].find { |s| s.keys.first == 'bootic' }['bootic']['access_token']
    raise 'No tiene token de acceso registrado' if token.blank?
    res = self.class.put("/shops/#{order.shop_id}/orders/#{order.id}",
                          headers: @headers.merge({ 'User-Agent' => @user_agent, 'Authorization' => "Bearer #{token}" }),
                          query: {},
                          body: { fulfillment: { tracking_code: tracking, courier_name: courier } }.to_json)
    raise "This order #{res['_embedded']['errors'].first['messages'].first}" if res['_class'].first == 'errors'
    order.update_attributes(status: res['status'])
  end
end
