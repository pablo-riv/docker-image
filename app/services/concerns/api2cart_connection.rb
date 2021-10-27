module Api2cartConnection
  extend ActiveSupport::Concern
  included do
    API_2_CART_API_KEY = '9eafdd708335342240c20c5a4ee7c7e7'.freeze

    def download_api2cart(setting, seller)
      config = setting.seller_configuration(seller)[seller]
      return if config['client_id'].blank?
      if seller == 'prestashop'
        orders = []
        statuses = [2, 3]
        params =
        {
          created_from: (DateTime.current - 10.days).to_formatted_s(:db),
          created_to: (DateTime.current + 2.days).to_formatted_s(:db),
          params: 'force_all',
          count: 300,
          sort_by: 'modified_at',
          sort_direction: 'desc'
        }
        api2cart_store = Api2cart::Store.new(API_2_CART_API_KEY, config['client_secret'])
        #statuses.each { |status| orders + api2cart_store.order_list(params.merge({order_status: status}))['order'] }

        statuses.each do |status|
          result = api2cart_store.order_list(params.merge({order_status: status}))['order']
          orders += result unless result.nil?
        end
        orders.map { |order| api2cart_to_hash(order, setting.company_id, seller) }
      else
        params =
          {
            created_from: (DateTime.current - 140.days).to_formatted_s(:db),
            created_to: (DateTime.current + 1.days).to_formatted_s(:db),
            params: 'force_all',
            count: 1200,
            sort_by: 'modified_at',
            sort_direction: 'desc'
          }
        api2cart_store = Api2cart::Store.new(API_2_CART_API_KEY, config['client_secret'])
        orders_downloaded = api2cart_store.order_list(params)['order']
        orders_downloaded = api2cart_store.order_list['order'] if orders_downloaded.blank?
        return if orders_downloaded.blank?
        orders_downloaded.map { |order| api2cart_to_hash(order, setting.company_id, seller) }
      end
    end

    def save_store(setting, seller)
      config = setting.seller_configuration(seller)[seller]
      return if config['client_id'].blank?

      found_store = find_store(config['client_id'], config['client_secret'])

      client = if found_store.blank?
        params = {
          store_url: config['client_id'].downcase,
          cart_id: find_card_id(seller) || seller.titleize,
          api_key: API_2_CART_API_KEY,
          store_key: config['client_secret']
        }
        url_composer = Api2cart::RequestUrlComposer.new(API_2_CART_API_KEY, '', 'cart_create', params)
        client = Api2cart::Client.new(url_composer.compose_request_url)
        puts client.make_request!
      else
        return unless found_store['store_key'] != config['client_secret']
        url_composer = Api2cart::RequestUrlComposer.new(API_2_CART_API_KEY, found_store['store_key'], 'cart_delete', {})
        client = Api2cart::Client.new(url_composer.compose_request_url)
        puts client.make_request!
        save_store(setting, seller)
      end
    end

    def api2cart_to_hash(order, company_id, seller)
      new_order_hash = hash_format(order)
      new_order_hash[:order_id] = new_order_hash.delete :id
      new_order_hash[:items] = new_order_hash.delete :order_products
      new_order_hash.merge!({ seller: seller, company_id: company_id })
      find_or_create_order(new_order_hash)
    end

    def find_card_id(seller)
      cart_list_url = Api2cart::RequestUrlComposer.new(API_2_CART_API_KEY, '', 'cart_list', {})
      cart_list_client = Api2cart::Client.new(cart_list_url.compose_request_url)
      cart_list = JSON.parse(cart_list_client.make_request!)
      found_cart_id = cart_list['result']['supported_carts'].first['cart'].select { |cart| cart['cart_name'].downcase.include? seller }.first['cart_id']
    end

    def find_store(store_url, store_key)
      store_list_url = Api2cart::RequestUrlComposer.new(API_2_CART_API_KEY, store_key, 'account_cart_list', {})
      store_list_client = Api2cart::Client.new(store_list_url.compose_request_url)
      store_list = JSON.parse(store_list_client.make_request!)
      found_store = store_list['result']['carts'].find { |store| store['url'].downcase.ends_with? store_url.downcase }
    end
  end
end
