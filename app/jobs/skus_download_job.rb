class SkusDownloadJob < ApplicationJob
  queue_as :downloads

  def perform(object)
    download = object[:company].downloads.create(kind: :xlsx, status: :init)
    data = SearchService::Sku.new(availables: object[:availables],
                                  company_id: object[:company].id,
                                  query: object[:query],
                                  value: object[:value],
                                  per: object[:per]).search
    link = Downloads::Sku.new(skus: data[:skus], object: object.merge(download: download)).xlsx
  rescue StandardError => e
    download.update_attributes(status: :failed)
    Rails.logger.info("🖨 **SkusDownloadJob**\nNo se pudo generar el descargable de skus para: #{object[:account].email} \n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace}".red.swap)
    Slack::Ti.new({}, {}).alert('', "**SkusDownloadJob**\nNo se pudo generar el descargable de skus para: #{object[:account].email} \n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
  end
end
