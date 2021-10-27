module Charges
  module Uploader
    def upload(charges: [], name: '', service: '')
      data = charges.map do |charge|
        [I18n.l(charge[:date].to_date, format: :months), I18n.t("activerecord.attributes.charges.statuses.#{charge[:state]}"), charge[:invoice], charge[:plan], charge[:shipping_price], charge[:overcharges], charge[:refunds], charge[:service_price], charge[:total]]
      end
      xlsx = SpreadsheetArchitect.to_xlsx(headers: ['Mes Facturado', 'Estado', 'Factura', 'Valor Base', 'Envíos', 'Sobrecargo', 'Reembolsos', service, 'Total a Pagar'],
                                          data: data)
      File.open("#{Rails.root}/public/xlsx/#{name}.xlsx", 'w+b') do |f|
        f.write(xlsx)
        client = ::Aws::S3::Resource.new
        bucket = client.bucket('packages-xls-shipit')
        dir = bucket.object("packages-xls-shipit/#{Time.current.year}/#{Time.current.month}/#{Time.current.day}/#{name}.xlsx")
        dir.put(body: xlsx, content_type: 'application/xlsx', acl: 'public-read')
        dir.public_url
      end
    end
  end
end
