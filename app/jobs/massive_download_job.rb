class MassiveDownloadJob < ApplicationJob
  queue_as :default

  def perform(object)
    packages_csv = SearchService::Package.new(from_date: object[:from],
                                              to_date: object[:to],
                                              status: object[:params][:by_status],
                                              payables: object[:params][:payable],
                                              returned: object[:params][:returned],
                                              courier: object[:params][:from_courier],
                                              branch_offices: object[:company].branch_offices.ids).search
    raise unless Package.generate_xlxs_file(packages_csv, object[:from], object[:to], object[:company].name, object[:with_series])

    file_name = "#{object[:company].name.gsub('/', '_')} Envíos #{object[:from]} - #{object[:to]}"
    file_path = "#{Rails.root}/public/#{file_name}.xlsx"
    subject = object[:with_series] ? "📦 Descarga masiva con números de serie" : "📦 #{file_name}"
    NotifyMailer.download_packages(file_name: file_name, file_path: file_path, email: object[:email], subject: subject).deliver
  rescue StandardError => e
    Slack::Ti.new({}, {}).alert('', "🖨 No se pudo generar el descargable del detalle de pedidos con números de serie solicitado para #{object[:email]} \n ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
  end
end
