class ShipmentsDownloadWorker < ApplicationJob
  include Sneakers::Worker
  from_queue 'core.shipments_download', env: nil, ack: true

  def work(object)
    transformed_object = HashWithIndifferentAccess.new(JSON.parse(object))
    data = SearchService::Shipment.new(transformed_object).download
    download = Download.find_by(id: transformed_object[:download][:id])
    link = Package.xlxs_file(shipments: data[:shipments],
                             from: transformed_object[:from_date],
                             to: transformed_object[:to_date],
                             company: transformed_object[:company],
                             fulfillment: transformed_object[:fulfillment],
                             download: download)
    raise I18n.t('errors.unprocessable') unless link.present?

    ack!
  rescue StandardError => e
    download.update_attributes(status: :failed)
    Slack::Ti.new({}, {}).alert('', "🖨 **ShipmentDownloadJob**\nNo se pudo generar el descargable del detalle de pedidos con números de serie solicitado para #{transformed_object[:account][:email]} \n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
    Sneakers.logger.info("🖨 **ShipmentDownloadWorker**\nNo se pudo generar el descargable del detalle de pedidos con números de serie solicitado para #{transformed_object[:account][:email]} \n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
    ack!
  ensure
    ack!
  end
end
