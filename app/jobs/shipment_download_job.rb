class ShipmentDownloadJob < ApplicationJob
  queue_as :downloads

  def perform(object)
    data = SearchService::Shipment.new(object).download
    link = Package.xlxs_file(data[:shipments], object[:from_date], object[:to_date], object[:company], object[:download])
    raise I18n.t('errors.unprocessable') unless link.present?
  rescue StandardError => e
    object[:download].update_attributes(status: :failed)
    Slack::Ti.new({}, {}).alert('', "🖨 **ShipmentDownloadJob**\nNo se pudo generar el descargable del detalle de pedidos con números de serie solicitado para  #{object[:account].email} \n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
  end
end
