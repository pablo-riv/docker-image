class FulfillmentPackageJob < ApplicationJob
  queue_as :fulfillment

  def perform(packages, company)
    inventories = {
      inventories_success: [],
      inventories_errors: [],
      company_id: company['id'],
      company_name: company['name']
    }
    packages.each do |package|
      begin
        next if package.is_sandbox? || package.reference.downcase.start_with?('test-')

        if package.fulfillment?
          raise unless package.retry_fulfillment

          quantity_items = package['inventory_activity']['inventory_activity_orders_attributes'].pluck('amount').map(&:to_i).sum
          inventories[:inventories_success] << { package_id: package.id,
                                                 item_amount_success: quantity_items,
                                                 reference: package['reference'],
                                                 sku_amount_success: package['inventory_activity']['inventory_activity_orders_attributes'].count }
        end
      rescue => e
        Rails.logger.info { "#{e.message}\n#{e.backtrace[0]}".red.swap }
        quantity_items = package['inventory_activity']['inventory_activity_orders_attributes'].pluck('amount').map(&:to_i).sum
        inventories[:inventories_errors] << {package_id: package.id,
                                             item_amount_errors: quantity_items,
                                             reference: package['reference'],
                                             sku_amount_errors: package['inventory_activity']['inventory_activity_orders_attributes'].count}
      end
    end
    NotificationMailer.ff_orders_status(inventories).deliver_now unless inventories[:inventories_errors].blank?
  end
end
