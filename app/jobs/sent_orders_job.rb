class SentOrdersJob < ApplicationJob
  queue_as :default

  def perform(current_account)
    headers = %w{Order_Reference Seller_Id Seller_Name SKUs Created_at Order_Number Customer_Name Shipping_Name Shipping_Address}
    attributes = %w{reference order_id seller skus created seller_reference customer_name shipping_name shipping_data}
    CSV.generate(headers: true) do |csv|
      csv << headers
      OrderService.where(sent: true, company_id: current_account.entity_specific.id).today.each do |order|
        items = case order.seller
                when 'bootic' then order.items
                when 'dafiti' then order.items['order_item'].class.name != 'Array' ? [order.items['order_item']] : order.items['order_item']
                when 'shopify' then order.items
                end
        items.each_with_index do |item, index|
          csv << attributes.map do |attri|
            case attri
            when 'skus' then order.item_sku(index)
            when 'created' then Date.parse(order.send(attri).to_s)
            else
              order.send(attri)
            end
          end
        end
      end
    end
  rescue StandardError => e
    OrderMailer.warn_about_something_happend('SentOrdersJob', e.message).deliver
    puts e.message.red
    "No se pudo construir la lista de ordenes, por favor contactanos a soporte@shipit.cl. #{e.message}"
  end
end
