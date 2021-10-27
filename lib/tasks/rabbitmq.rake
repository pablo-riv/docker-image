namespace :rabbitmq do
  desc 'Setup routing'
  task setup: :environment do
    require 'bunny'
    conn = Bunny.new("#{Rails.configuration.rabbitmq[:protocol]}://#{Rails.configuration.rabbitmq[:user]}:#{Rails.configuration.rabbitmq[:password]}@#{Rails.configuration.rabbitmq[:host]}:#{Rails.configuration.rabbitmq[:port]}")
    conn.start

    channel = conn.create_channel
    ##
    # SETTING CHANNEL
    ##
    x = channel.fanout('core.settings')
    queue = channel.queue('core.create_settings', durable: true).bind('core.settings')
    x = channel.fanout('opit.settings')
    queue = channel.queue('opit.get_settings', durable: true).bind('opit.settings')

    ##
    # MASS CREATE PICK & PACK CHANNEL
    ##
    x = channel.fanout('core.mass')
    queue = channel.queue('core.mass_create', durable: true).bind('core.mass')

    x = channel.fanout('ff.webhook_sku')
    queue = channel.queue('core.webhook_sku', durable: true).bind('ff.webhook_sku')

    x = channel.fanout('core.mass')
    queue = channel.queue('pp.update_package', durable: true).bind('core.mass')

    x = channel.fanout('core.inventory')
    queue = channel.queue('core.inventory_activity', durable: true).bind('core.inventory')

    x = channel.fanout('fulfillment.inventory')
    queue = channel.queue('fulfillment.set_sku', durable: true).bind('fulfillment.inventory')

    x = channel.fanout('ff.skus')
    queue = channel.queue('ff.set_sku_core', durable: true).bind('ff.skus')

    x = channel.fanout('core.companies')
    queue = channel.queue('core.new_company', durable: true).bind('core.companies')

    x = channel.fanout('staff.companies')
    queue = channel.queue('staff.set_company', durable: true).bind('staff.companies')

    x = channel.fanout('core.heros')
    queue = channel.queue('core.set_hero', durable: true).bind('core.heros')

    x = channel.fanout('staff.heros')
    queue = channel.queue('staff.new_hero', durable: true).bind('staff.heros')

    x = channel.fanout('core.post_prices')
    queue = channel.queue('core.get_prices', durable: true).bind('core.post_prices')

    x = channel.fanout('api.post_prices')
    queue = channel.queue('core.get_prices', durable: true).bind('api.post_prices')

    x = channel.fanout('opit.patch_prices')
    queue = channel.queue('opit.get_prices', durable: true).bind('opit.patch_prices')

    x = channel.fanout('core.post_tracking')
    queue = channel.queue('core.get_tracking', durable: true).bind('core.post_tracking')

    x = channel.fanout('opit.patch_tracking')
    queue = channel.queue('opit.get_tracking', durable: true).bind('opit.patch_tracking')

    x = channel.fanout('opit.patch_status')
    queue = channel.queue('opit.get_status', durable: true).bind('opit.patch_status')

    x = channel.fanout('staff.post_status')
    queue = channel.queue('staff.get_status', durable: true).bind('staff.post_status')

    x = channel.fanout('staff.package_status')
    queue = channel.queue('core.package_status_from_opit', durable: true).bind('staff.package_status')

    x = channel.fanout('staff.calculate_price')
    queue = channel.queue('staff.set_price', durable: true).bind('staff.calculate_price')

    x = channel.fanout('staff.set_tracking')
    queue = channel.queue('core.set_tracking', durable: true).bind('staff.set_tracking')

    x = channel.fanout('staff.retry_fulfillment')
    queue = channel.queue('core.retry_fulfillment', durable: true).bind('staff.retry_fulfillment')

    x = channel.fanout('staff.create_trello')
    queue = channel.queue('core.create_trello', durable: true).bind('staff.create_trello')

    x = channel.fanout('core.update_seller_order')
    queue = channel.queue('order.update_seller_order', durable: true).bind('core.update_seller_order')

    x = channel.fanout('statuses.update_seller_order')
    queue = channel.queue('order.update_seller_order', durable: true).bind('statuses.update_seller_order')

    x = channel.fanout('shopify.bulk_seller_order')
    queue = channel.queue('order.bulk_seller_order', durable: true).bind('shopify.bulk_seller_order')

    x = channel.fanout('core.reindex_order')
    queue = channel.queue('elastic.reindex_order', durable: true).bind('core.reindex_order')

    x = channel.fanout('core.reindex_shipment')
    queue = channel.queue('elastic.reindex_shipment', durable: true).bind('core.reindex_shipment')

    x = channel.fanout('staff.reindex_shipment')
    queue = channel.queue('elastic.reindex_shipment', durable: true).bind('staff.reindex_shipment')

    x = channel.fanout('statuses.reindex_shipment')
    queue = channel.queue('elastic.reindex_shipment', durable: true).bind('statuses.reindex_shipment')

    x = channel.fanout('order.reindex_order')
    queue = channel.queue('core.reindex_order', durable: true).bind('order.reindex_order')
    queue = channel.queue('elastic.reindex_order', durable: true).bind('order.reindex_order')

    x = channel.fanout('core.callbacks')
    queue = channel.queue('elastic.set_callbacks', durable: true).bind('core.callbacks')

    x = channel.fanout('staff.callbacks')
    queue = channel.queue('elastic.set_callbacks', durable: true).bind('staff.callbacks')

    x = channel.fanout('core.drop_out_notifications')
    queue = channel.queue('notifications.drop_out_notifications', durable: true).bind('core.drop_out_notifications')

    x = channel.fanout('api.buyer_email')
    queue = channel.queue('notifications.buyer_email', durable: true).bind('api.buyer_email')

    x = channel.fanout('api.buyer_whatsapp')
    queue = channel.queue('notifications.buyer_whatsapp', durable: true).bind('api.buyer_whatsapp')

    x = channel.fanout('api.shipment_notifications')
    queue = channel.queue('notifications.shipment_notifications', durable: true).bind('api.shipment_notifications')

    x = channel.fanout('core.shipment_notifications')
    queue = channel.queue('notifications.shipment_notifications', durable: true).bind('core.shipment_notifications')

    x = channel.fanout('api.returned_notifications')
    queue = channel.queue('notifications.returned_notifications', durable: true).bind('api.returned_notifications')

    x = channel.fanout('api.returns_to_client_notifications')
    queue = channel.queue('notifications.returns_to_client_notifications', durable: true).bind('api.returns_to_client_notifications')

    x = channel.fanout('api.returns_to_buyer_notifications')
    queue = channel.queue('notifications.returns_to_buyer_notifications', durable: true).bind('api.returns_to_buyer_notifications')

    x = channel.fanout('api.generic_notifications')
    queue = channel.queue('notifications.generic_notifications', durable: true).bind('api.generic_notifications')

    x = channel.fanout('api.area_not_assign')
    queue = channel.queue('notifications.area_not_assign', durable: true).bind('api.area_not_assign')

    x = channel.fanout('api.company_change_address')
    queue = channel.queue('notifications.company_change_address', durable: true).bind('api.company_change_address')

    x = channel.fanout('api.package_without_hero')
    queue = channel.queue('notifications.package_without_hero', durable: true).bind('api.package_without_hero')

    x = channel.fanout('api.without_address')
    queue = channel.queue('notifications.without_address', durable: true).bind('api.without_address')

    x = channel.fanout('api.test_buyer')
    queue = channel.queue('notifications.test_buyer', durable: true).bind('api.test_buyer')

    x = channel.fanout('staff.test_buyer')
    queue = channel.queue('notifications.test_buyer', durable: true).bind('staff.test_buyer')

    x = channel.fanout('api.reset_password')
    queue = channel.queue('notifications.reset_password', durable: true).bind('api.reset_password')

    x = channel.fanout('api.new_user')
    queue = channel.queue('notifications.new_user', durable: true).bind('api.new_user')

    x = channel.fanout('api.pickup_notifications')
    queue = channel.queue('notifications.pickup_notifications', durable: true).bind('api.pickup_notifications')

    x = channel.fanout('staff.pickup_notifications')
    queue = channel.queue('notifications.pickup_notifications', durable: true).bind('staff.pickup_notifications')

    x = channel.fanout('api.create_manifest')
    queue = channel.queue('core.create_manifest', durable: true).bind('api.create_manifest')

    x = channel.fanout('api.manual_manifest')
    queue = channel.queue('core.manual_manifest', durable: true).bind('api.manual_manifest')

    x = channel.fanout('api.shipments_download')
    queue = channel.queue('core.shipments_download', durable: true).bind('api.shipments_download')

    x = channel.fanout('api.reindex_order')
    queue = channel.queue('elastic.reindex_order', durable: true).bind('api.reindex_order')

    x = channel.fanout('api.reindex_shipment')
    queue = channel.queue('elastic.reindex_shipment', durable: true).bind('api.reindex_shipment')

    x = channel.fanout('api.callbacks')
    queue = channel.queue('elastic.set_callbacks', durable: true).bind('api.callbacks')

    x = channel.fanout('api.customer_satisfaction')
    queue = channel.queue('core.customer_satisfaction', durable: true).bind('api.customer_satisfaction')

    x = channel.fanout('api.change_package_address')
    queue = channel.queue('core.change_package_address', durable: true).bind('api.change_package_address')
    x = channel.fanout('predictor.update_delivery_dates')
    queue = channel.queue('core.update_delivery_dates', durable: true).bind('predictor.update_delivery_dates')

    x = channel.fanout('api.request_delivery_date')
    queue = channel.queue('predictor.request_delivery_date', durable: true).bind('api.request_delivery_date')

    x = channel.fanout('core.request_delivery_date')
    queue = channel.queue('predictor.request_delivery_date', durable: true).bind('core.request_delivery_date')

    x = channel.fanout('staff.request_delivery_date')
    queue = channel.queue('predictor.request_delivery_date', durable: true).bind('staff.request_delivery_date')

    x = channel.fanout('api.management_transition')
    queue = channel.queue('core.management_transition', durable: true).bind('api.management_transition')

    x = channel.fanout('core.management_transition')
    queue = channel.queue('core.management_transition', durable: true).bind('core.management_transition')

    x = channel.fanout('staff.management_transition')
    queue = channel.queue('core.management_transition', durable: true).bind('staff.management_transition')

    x = channel.fanout('core.proactive_monitoring')
    queue = channel.queue('notifications.proactive_monitoring', durable: true).bind('core.proactive_monitoring')

    x = channel.fanout('opit.reindex_shipment')
    queue = channel.queue('elastic.reindex_shipment', durable: true).bind('opit.reindex_shipment')

    x = channel.fanout('opit.package_status')
    queue = channel.queue('core.package_status_from_opit', durable: true).bind('staff.package_status')

    x = channel.fanout('staff.buyer_new_tracking_number')
    queue = channel.queue('notifications.buyer_new_tracking_number', durable: true).bind('staff.buyer_new_tracking_number')

    x = channel.fanout('staff.create_refund_ticket')
    queue = channel.queue('core.create_refund_ticket', durable: true).bind('staff.create_refund_ticket')

    x = channel.fanout('api.refund_document_synchronize_zendesk')
    queue = channel.queue('core.refund_document_synchronize_zendesk', durable: true).bind('api.refund_document_synchronize_zendesk')

    x = channel.fanout('api.proactive_monitoring_wrong_address')
    queue = channel.queue('core.proactive_monitoring_wrong_address', durable: true).bind('api.proactive_monitoring_wrong_address')

    x = channel.fanout('internal.set_tracking')
    queue = channel.queue('core.set_tracking', durable: true).bind('internal.set_tracking')

    x = channel.fanout('internal.reindex_shipment')
    queue = channel.queue('elastic.reindex_shipment', durable: true).bind('internal.reindex_shipment')

    x = channel.fanout('staff.customer_satisfaction_mailer')
    queue = channel.queue('notifications.customer_satisfaction_mailer', durable: true).bind('staff.customer_satisfaction_mailer')

    x = channel.fanout('statuses.customer_satisfaction_mailer')
    queue = channel.queue('notifications.customer_satisfaction_mailer', durable: true).bind('statuses.customer_satisfaction_mailer')

    x = channel.fanout('internal.returns_to_client_notifications')
    queue = channel.queue('notifications.returns_to_client_notifications', durable: true).bind('internal.returns_to_client_notifications')

    conn.close
  end
end
