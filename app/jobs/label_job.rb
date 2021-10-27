class LabelJob < ApplicationJob
  queue_as :printers

  def perform(packages, company, account, download)
    download.update_attributes(status: :init)
    service = LabelService.new(packages, company, account)
    link = service.pdf
    download.update_attributes(status: :success, downloaded: true, link: link)
    Package.where(id: packages.pluck(:id)).update_all(label_printed: true, printed_date: Date.current)
    link
  rescue => e
    download.update_attributes(status: :failed)
    Slack::Ti.new({}, {}).alert('', "🖨 Cliente #{company.name} no puede generar PDF\n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
  end
end
