# This class work as a main class for the different integrations avalibles, centralizing methods
class SellerConnection
  include BooticConnection
  include DafitiConnection
  include BsaleConnection
  include ShopifyConnection
  include Api2cartConnection
  include VtexConnection

  def initialize(seller_name, client_id = nil, client_secret = nil, store_name = nil)
    @seller_name = seller_name
    @client_id = client_id
    @client_secret = client_secret
    @store_name = store_name
    @seller = {}
  end

  def download_packages_from(setting, seller = nil, from_date, to_date)
    api2cart_allowed_sellers = %w[woocommerce prestashop opencart]
    raise 'Sin tienda seleccionada' if seller.nil?
    # configuration(setting) if seller == 'bootic'
    save_store(setting, seller) if api2cart_allowed_sellers.include?(seller)
    case seller
    when 'bootic' then download_bootic(setting)
    when 'dafiti' then download_dafiti(setting)
    when 'bsale' then download_bsale(setting)
    when 'shopify' then download_shopify(setting, from_date, to_date)
    when 'woocommerce', 'prestashop', 'opencart' then download_api2cart(setting, seller)
    when 'vtex' then download_vtex(setting)
    end
  end

  def update_orders_from(order, package, setting = nil)
    case order.seller
    when 'dafiti' then update_dafiti_order(order, package)
    when 'bootic' then update_bootic_order(order, package, setting)
    when 'shopify' then update_shopify_order(order.order_id, package)
    when 'vtex' then update_vtex_order(order, package)
    end
    order.update_attributes(package_tracking_number: package.tracking_number, package_status: package.status)
  end

  def find_or_create_order(object) # KEYS: order, perform, version
    object = { order: object, perform: (Rails.env.production? ? 'later' : 'now'), version: 1 } if object[:order].blank?
    FindOrCreateOrderJob.send("perform_#{object[:perform]}", { order: object[:order].to_json, version: object[:version] })
  end

  def hash_format(prev_hash)
    prev_hash.inject({}) do |memo, (key, values)|
      values = hash_format(values) if values.is_a?(Hash)
      if values.is_a?(Array)
        values = values.map do |value|
          if values.is_a?(Hash)
            hash_format(value)
          else
            value
          end
        end
      end
      values = hash_format(values.properties) if values.class.name == 'BooticClient::Entity'
      memo[key.to_s.underscore.to_sym] = values
      memo
    end
  end
end
