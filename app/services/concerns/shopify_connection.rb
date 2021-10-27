module ShopifyConnection
  extend ActiveSupport::Concern
  included do
    def download_shopify(setting, from_date, to_date)
      shopify = ShopifyService.new(@client_id, @client_secret, @store_name, from_date, to_date)
      response = shopify.orders(setting.company_id, self)
      return unless response.present?

      response
    end

    def update_shopify_order(order_id, package, from_date = (DateTime.current - 1.week).to_s, to_date = DateTime.current.to_s)
      shopify = ShopifyService.new(@client_id, @client_secret, @store_name, from_date, to_date)
      tracking_url = package.courier_url
      shopify_order = shopify.order(order_id)
      status = case package.status.to_s
               when 'created', 'in_preparation' then 'pending'
               when 'in_route' then 'success'
               when 'delivered' then 'success'
               end
      params = {
        order: shopify_order,
        status: status,
        tracking: package.tracking_number,
        courier: package.courier_for_client.capitalize,
        tracking_url: tracking_url
      }
      fulfillment = shopify.fulfillment(params)
      return unless fulfillment.blank?

      shopify_order.fulfillments.push(fulfillment)
      shopify_order.save
    end

    def shopify_to_hash(element, company_id)
      new_hash_element = element
      new_hash_element[:order_id] = new_hash_element.delete('id')
      new_hash_element[:fulfillment_status] = 'pending' if  new_hash_element[:fulfillment_status].nil?
      new_hash_element[:items] = new_hash_element.delete('line_items')
      new_hash_element[:address_shipping] = new_hash_element.delete('shipping_address')
      new_hash_element[:address_billing] = new_hash_element.delete('billing_address')
      new_hash_element.merge!(company_id: company_id, seller: 'shopify', status: 'pending')
      find_or_create_order(new_hash_element)
    end
  end
end
