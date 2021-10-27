class DownloadSellerOrdersJob < TrackedJob
  queue_as :default

  def perform(sellers = [], company = nil, from_date, to_date)
    sellers = sellers.try(:compact)
    puts company.try(:id).to_s.yellow
    client_download = DownloadService.where(company_id: company.try(:id)).first
    puts client_download.to_s.yellow
    if client_download.blank?
      client_download = DownloadService.create(company_id: company.try(:id), downloading: true, last_time: DateTime.current)
    end
    client_download.update_last_download(true)
    puts client_download.to_s.green
    sellers.each do |seller|
      next if seller.blank? || (seller[:client_id].blank? && seller[:name] != 'bootic')
      marketplace = SellerConnection.new(seller[:name], seller[:client_id], seller[:client_secret], seller[:store_name])
      begin
        marketplace.download_packages_from(seller[:setting], seller[:name], from_date, to_date)
      rescue => exception
        puts exception.message
      end
    end
    client_download.update_last_download(false)
  rescue StandardError => e
    puts client_download.to_s.red
    client_download.update_last_download(false)
    Publisher.publish('status_log', { message: "client: DownloadSellerOrdersJob company #{company.try(:id)} #{e.message}" })
    puts "Hubo un problema intentando descargar las ordenes: #{e.message}".red
  end
end
