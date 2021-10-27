class InventoryDownloadJob < ApplicationJob
  queue_as :downloads

  def perform(object)
    @download = object[:company].downloads.create(kind: :xlsx, status: :init)
    data = SearchService::Inventory.new(company_id: object[:company].id,
                                        from_date: object[:from_date],
                                        to_date: object[:to_date],
                                        query: object[:query],
                                        value: object[:value],
                                        per: 500).search
    link = Downloads::Inventory.new(inventories: data[:inventories], object: object.merge(download: @download)).xlsx
  rescue StandardError => e
    @download.update_attributes(status: :failed)
    Rails.logger.info("🖨 **InventoryDownloadJob**\nNo se pudo generar el descargable de inventario para: #{object[:account].email} \n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace}".red.swap)
    Slack::Ti.new({}, {}).alert('', "**InventoryDownloadJob**\nNo se pudo generar el descargable de inventario para: #{object[:account].email} \n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
  end
end
