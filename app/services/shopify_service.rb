class ShopifyService
  def initialize(client_id, client_secret, store_name, from_date, to_date)
    @from_date = from_date
    @to_date = to_date
    ShopifyAPI::Base.site = "https://#{client_id}:#{client_secret}@#{store_name}.myshopify.com/admin"
  end

  def orders(company_id, connection, limit = 250)
    count_orders = ShopifyAPI::Order.count(params: { financial_status: 'paid', created_at_min: @from_date.to_s, created_at_max: @to_date.to_s })
    # production changes
    pages = (count_orders.to_f / limit).ceil
    puts "TOTAL PAGES: #{pages}".green.swap
    puts "MAX PAGES: #{[1, pages].max}".green.swap
    orders_count = 0
    [1, pages].max.times.each do |page|
      puts "PAGE: #{page} / #{pages}...".green.swap
      unformatted_order = ShopifyAPI::Order.all(params: { created_at_min: @from_date.to_s, created_at_max: @to_date.to_s, financial_status: 'paid', limit: limit, page: page })
      next if unformatted_order.blank?

      collection = JSON.parse(unformatted_order.to_json)
      collection.each do |order|
        new_hash_element = order
        new_hash_element[:order_id] = new_hash_element.delete('id')
        new_hash_element[:fulfillment_status] = 'pending' if  new_hash_element[:fulfillment_status].nil?
        new_hash_element[:items] = new_hash_element.delete('line_items')
        new_hash_element[:address_shipping] = new_hash_element.delete('shipping_address')
        new_hash_element[:address_billing] = new_hash_element.delete('billing_address')
        new_hash_element.merge!(company_id: company_id, seller: 'shopify', status: 'pending')
        connection.find_or_create_order(new_hash_element)
        orders_count += 1
      end

      break if page == pages
    end

    orders_count
  end

  def order(id)
    ShopifyAPI::Order.find(id)
  end

  def fulfillment(params)
    locations = ShopifyAPI::Location.all.select { |l| l.attributes[:active] }
    location = locations.select { |l| l.attributes[:id] == params[:order].attributes[:location_id] }.first
    fulfillment_payload = {
      location_id: location.try(:id).presence || locations.first.id,
      tracking_url: params[:tracking_url],
      tracking_number: params[:tracking],
      tracking_company: 'Other',
      status: params[:status],
      line_items: params[:order].line_items.map { |ln| { id: ln.id } }
    }.with_indifferent_access
    prefix_options = { order_id: params[:order].id }
    new_fulfillment = ShopifyAPI::Fulfillment.new
    new_fulfillment.attributes = fulfillment_payload
    new_fulfillment.prefix_options = prefix_options
    return new_fulfillment if new_fulfillment.save
  end

  def fulfilled_by_package(params = {})
    return if params[:reference].blank?
    order = ShopifyAPI::Order.all(params: {created_at_min: '05-10-2018', name: params[:reference], finacial_status: 'paid' }).first
    return if order.blank? || order.fulfillment_status == 'fulfilled'

    location = ShopifyAPI::Location.first

    fulfillment_payload = {
      location_id: location.id,
      tracking_url: params[:tracking_url],
      tracking_number: params[:tracking],
      tracking_company: 'Other',
      status: params[:status]
    }

    prefix_options = { order_id: order.id }
    new_fulfillment = ShopifyAPI::Fulfillment.new
    new_fulfillment.attributes = fulfillment_payload
    new_fulfillment.prefix_options = prefix_options
    return new_fulfillment if new_fulfillment.save
  end
end
