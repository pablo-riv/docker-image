class FindOrCreateOrderJob < TrackedJob
  queue_as :default

  def perform(object)
    # object = JSON.parse(object.to_json).with_indifferent_access
    # object = { order: object, perform: 'later', version: 1 } if object[:order].blank?
    order_hash = JSON.parse(object[:order]).with_indifferent_access
    puts order_hash.to_s.yellow
    order = OrderService.where(seller_reference: OrderService.new(order_hash).set_seller_reference, seller: order_hash[:seller], company_id: order_hash[:company_id])[0]
    puts order.blank?.to_s.blue.swap
    order =
      if order.blank?
        sent = order_hash[:sent].present? ? (order_hash[:sent].try(:to_s) == 'true') : false
        OrderService.create(order_hash.merge!(sent: sent))
      else
        order.update_attributes(order_hash)
        order
      end
    order = OrderService.find_by(_id: order._id)
    order.set_base_info(object[:version] || 2)
    order
  rescue => e
    Publisher.publish('status_log', { message: "client: FindOrCreateOrderJob company #{order_hash[:company_id]} #{e.message} #{e.backtrace.first(5).join("\n")}" })
    puts "Hubo un problema intentando crear la orden: #{e.message} #{e.backtrace.first(5).join("\n")}".red
  end
end
