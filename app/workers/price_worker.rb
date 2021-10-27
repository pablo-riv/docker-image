class PriceWorker < MixpanelTrackWorker
  include Sneakers::Worker
  from_queue 'opit.get_prices'

  def work(data)
    object = JSON.parse(data)
    unless object['id'].nil?
      Sneakers::logger.info { 'Updating: ============================================='.yellow.swap }
      package = Package.find_by(id: object['id'])
      raise 'Envio no encontrado' unless package.present?

      object['courier_for_client'] = package.courier_for_client if package.courier_for_client.present?
      courier_selected = !object['courier_selected'].nil? && object['courier_selected'] == true ? true : false
      begin
        validate_courier = { courier_for_client: object['courier_for_client'], reference: package.reference, destiny: package.destiny, is_payable: package.is_payable, address_attributes: { commune_id: package.address.commune_id } }.with_indifferent_access
        account = package.company.current_account
        if PackageService.validate_shipment(validate_courier)
          prices = Price::Shipment.new(
            subscription: package.company_current_subscription,
            courier_selected: courier_selected,
            apply_courier_discount: package.apply_courier_discount,
            total_price: package.total_price,
            shipping_price: object['shipping_price'].try(:to_f),
            shipping_cost: object['shipping_cost'].try(:round),
            insurance_price: package.insurance_price,
            material_extra: package.material_extra,
            is_paid_shipit: package.is_paid_shipit,
            is_payable: package.is_payable,
            packing: package.packing,
            height: package.height,
            width: package.width,
            length: package.length
          ).calculate_prices

          Sneakers::logger.info { "prices: #{prices}".green.swap }
          Rails.logger.info { 'Done!: ============================================='.yellow.swap }
          attributes = {
            courier_for_entity: object['courier_for_entity'],
            courier_for_client: object['courier_for_client'],
            volume_ranking: object['volume_raking'],
            delivery_time: object['delivery_time'],
            volume_price: object['volume_price'].try(:to_f),
            courier_selected: courier_selected,
            spreadsheet_versions: object['spreadsheet_versions'],
            spreadsheet_versions_destinations: object['spreadsheet_versions_destinations'],
            total_is_payable: prices[:total_is_payable],
            material_extra: prices[:material_extra],
            shipping_price: prices[:shipping_price],
            shipping_cost: prices[:shipping_cost],
            total_price: prices[:total_price],
            discount_amount: prices[:discount_amount],
            discount_percent: prices[:discount_percent]
          }
          package.update_columns(attributes)

          package.set_tcc
          package.set_label_size
          package.publish_reindex
          package.alert_price_too_high
          package.set_tracking
          track_action(source: 'get_prices', data: JSON.parse(data), result: attributes, account: account, status: 'success')
        end
      rescue => e
        Rails.logger.info { "ERROR: #{e.message}\nBACKTRACE: #{e.backtrace[0]}".yellow.swap }
        account = package.branch_office.company.current_account
        PickupService.archive_items(package.id)
        NotificationMailer.courier_indirect_failure(courier: object['courier_for_client'], package: package.reference, destiny: package.address.commune.name, email: account.email).deliver_now
        package.update_columns(is_archive: true)
        track_action(data: JSON.parse(data), result: { message: e.message }, status: 'error', account: account)
      end
    end
    ack!
  rescue StandardError => e
    Sneakers::logger.info e.message.red
    Publisher.publish('status_log', { message: "opit.get_prices: #{e.message}" })
    ack!
  ensure
    ack!
  end
end
