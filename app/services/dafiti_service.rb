class DafitiService
  include HTTParty

  def initialize(user_id, key)
    url_production = 'https://sellercenter-api.dafiti.cl/'
    @key = key
    @user_id = user_id
    @format = 'JSON'
    @version = '1.0'
    @api_uri = url_production
    self.class.base_uri @api_uri
  end

  def time_stamp
    t = Time.current
    t.iso8601
  end

  def generate_signature(url)
    digest = OpenSSL::Digest.new('sha256')
    @signature = OpenSSL::HMAC.hexdigest(digest, @key, url)
  end

  def generate_url(params = {})
    time = time_stamp
    parameters = {  'Action': @action,
                    'Format': @format,
                    'Timestamp': CGI.escape(time),
                    'UserID': CGI.escape(@user_id),
                    'Version': @version }
    parameters.merge!(params)
    parameters = parameters.sort.to_h
    CGI.unescape(parameters.to_query)
  end

  def build(action, form_method = 'GET', params = {})
    @action = action
    @method = form_method
    @params = params
    url = generate_url(params)
    @signature = generate_signature(url)
    "?#{url}&Signature=#{@signature}"
  end

  def request(action = '', form_method = 'GET', params = {}, body = '')
    @url = build(action, form_method, params)
    case form_method
    when 'GET' then build_request(form_method, @url, params)
    when 'DELETE' then build_request(form_method, @url, body)
    when 'POST' then build_request(form_method, @url, body)
    when 'PUT' then build_request(form_method, @url, params)
    end
  end

  def build_request(form_method, url, params = nil)
    if form_method == 'GET'
      response = self.class.send(form_method.downcase, "#{self.class.base_uri}#{url}")
    elsif form_method == 'POST' || form_method == 'UPDATE' || form_method == 'DELETE'
      response = self.class.send(form_method.downcase, "#{self.class.base_uri}#{url}", body: params)
    end
    puts response.request.last_uri.to_s.magenta
    puts response.to_s.blue
    response.include?('SuccessResponse') ? response['SuccessResponse']['Body'] : response
  end

  def order(order_id)
    params = { 'OrderId': order_id }
    response = request_api('GetOrder', 'GET', params)
    response.empty? ? nil : response['Orders']['Order']
  end

  def orders(status = nil)
    params = { 'Limit': 50, 'SortDirection': 'DESC' }
    params[:Status] = status unless status.blank?
    response = request_api('GetOrders', 'GET', params)
    response.empty? ? nil : response['Orders']
  end

  def order_items(order_id)
    params = { 'OrderId': order_id }
    response = request_api('GetOrderItems', 'GET', params)
    response.empty? ? nil : response
  end

  def shipment_providers
    response = request_api('GetShipmentProviders', 'GET')
    response.empty? ? nil : response
  end

  def create_webhook(body)
    response = request_api('CreateWebhook', 'POST', {}, body)
    response.empty? ? nil : response
  end

  def delete_webhook(body)
    response = request_api('DeleteWebhook', 'POST', {}, body)
    response.empty? ? nil : response
  end

  def item_status(status, id = nil, ids = nil, tracking_number = nil, provider = nil)
    params = arg_params(:OrderItemId, id,
                        :OrderItemIds, (ids.blank? ? nil : CGI.escape(ids.to_s.gsub(/\s+/, ''))),
                        :TrackingNumber, tracking_number,
                        :ShippingProvider, provider,
                        :DeliveryType, 'dropship')
    case status
    when 'to_marketplace' then request_api('SetStatusToPackedByMarketplace', 'POST', params)
    when 'created', 'in_preparation' then request_api('SetStatusToReadyToShip', 'POST', params)
    when 'in_route' then request_api('SetStatusToShipped', 'POST', params)
    when 'delivered' then request_api('SetStatusToDelivered', 'POST', params)
    when 'failed' then request_api('SetStatusToFailedDelivery', 'POST', params)
    end
  end

  def request_api(endpoint, request_method, query_params = {}, body = {})
    request(endpoint, request_method, query_params, body)
  end

  def arg_params(*args)
    Hash[*args].delete_if { |_key, value| value.blank? }
  end
end
