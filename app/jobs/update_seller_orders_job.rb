class UpdateSellerOrdersJob < ApplicationJob
  queue_as :default

  def perform(package)
    puts package.to_json.red
    setting = Setting.fullit(package.branch_office.company.id)
    seller = package.mongo_order_seller
    order = OrderService.find_by(_id: package.mongo_order_id)
    same = (order.try(:package_tracking_number) == package.tracking_number && order.try(:package_status) == package.status)
    return if order.blank? || package.tracking_number.blank? || package.status.blank?

    client_id = ''
    client_secret = ''
    store_name = ''
    setting.configuration['fullit']['sellers'].each do |market|
      next unless seller == market.keys.first

      client_id = market[seller]['client_id']
      client_secret = market[seller]['client_secret']
      store_name = market[seller]['store_name'] if ['shopify', 'vtex'].include?(seller)
    end
    SellerConnection.new(seller, client_id, client_secret, store_name).update_orders_from(order, package, setting)
  rescue StandardError => e
    Publisher.publish('status_log', {message: "client: UpdateSellerOrdersJob branch_office #{package.branch_office_id} #{e.message}" })
    puts "Hubo un problema intentando actualizar los estados de las ordenes: #{e.message.red}".red
  end
end
