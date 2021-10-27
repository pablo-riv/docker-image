module Downloable
  extend ActiveSupport::Concern

  module ClassMethods
    def xlxs_file(shipments, from, to, company, download)
      fulfillment = company.fulfillment?
      download.update!(status: :init)
      File.open("#{Rails.root}/public/xlsx/#{company.name.tr('/', '_')} Envíos #{from.tr('/', '-')} - #{to.tr('/', '-')}.xlsx", 'w+b') do |f|
        data = []
        download.update!(status: :downloading)
        shipments.map do |shipment|
          if fulfillment
            series = shipment.ff_series
            ff_series = series.present? ? series : ['name': '', 'sku': { 'name': '' }]
            ff_series.map do |ff_serie|
              data << shipment.ff_spreadsheet_columns(ff_serie.with_indifferent_access)
            end
          else
            data << shipment.spreadsheet_values
          end
        end
        f.write(SpreadsheetArchitect.to_xlsx(headers: shipments.first.spreadsheet_headers(fulfillment), data: data))
      end
      client = ::Aws::S3::Resource.new
      bucket = client.bucket('packages-xls-shipit')
      dir = bucket.object("packages-xls-shipit/#{Time.current.year}/#{Time.current.month}/#{Time.current.day}/#{company.name} #{Time.now.strftime("%d-%m-%Y %H.%M.%S")}.xlsx")
      dir.put(body: File.read("#{Rails.root}/public/xlsx/#{company.name.tr('/', '_')} Envíos #{from.tr('/', '-')} - #{to.tr('/', '-')}.xlsx"), content_type: 'application/xlsx', acl: 'public-read')
      download.update_attributes(status: :success, downloaded: true, link: dir.public_url)
      dir.public_url
    end
  rescue StandardError => e
    download.update_attributes(status: :failed)
  end

  def spreadsheet_columns
    spreadsheet_headers.map.with_index { |head, index| [head, spreadsheet_values[index]]}
  end

  def spreadsheet_headers(ff_package = false)
    temp_headers = [I18n.t('activerecord.attributes.package.id'),
                    I18n.t('activerecord.attributes.package.created_at'),
                    I18n.t('activerecord.attributes.package.reference'),
                    I18n.t('activerecord.attributes.package.tracking_number'),
                    I18n.t('activerecord.attributes.package.courier_for_client'),
                    I18n.t('activerecord.attributes.package.items_count'),
                    I18n.t('activerecord.attributes.package.is_returned'),
                    I18n.t('activerecord.attributes.package.full_name'),
                    I18n.t('activerecord.attributes.package.commune.name'),
                    I18n.t('activerecord.attributes.package.length'),
                    I18n.t('activerecord.attributes.package.width'),
                    I18n.t('activerecord.attributes.package.height'),
                    I18n.t('activerecord.attributes.package.weight'),
                    I18n.t('activerecord.attributes.package.volume'),
                    I18n.t('activerecord.attributes.package.volume_price'),
                    I18n.t('activerecord.attributes.package.is_payable'),
                    I18n.t('activerecord.attributes.package.is_paid_shipit'),
                    I18n.t('activerecord.attributes.package.destiny'),
                    I18n.t('activerecord.attributes.package.courier_selected'),
                    I18n.t('activerecord.attributes.package.shipping_price'),
                    I18n.t('activerecord.attributes.package.material_extra'),
                    I18n.t('activerecord.attributes.package.total_is_payable'),
                    I18n.t('activerecord.attributes.package.checkout'),
                    I18n.t('activerecord.attributes.package.courier_status_updated_at'),
                    I18n.t('activerecord.attributes.package.shipit_status_updated_at'),
                    I18n.t('activerecord.attributes.package.total_price'),
                    I18n.t('activerecord.attributes.package.status'),
                    I18n.t('activerecord.attributes.package.courier_status'),
                    I18n.t('activerecord.attributes.insurance.extra'),
                    I18n.t('activerecord.attributes.insurance.ticket_amount'),
                    I18n.t('activerecord.attributes.insurance.ticket_number'),
                    I18n.t('activerecord.attributes.insurance.detail'),
                    I18n.t('activerecord.attributes.insurance.price'),
                    I18n.t('activerecord.attributes.package.email')]

    if ff_package
      temp_headers << I18n.t('activerecord.attributes.package.serie')
      temp_headers << I18n.t('activerecord.attributes.package.sku_name')
    end
    temp_headers
  end

  def spreadsheet_values
    [id,
     created_at.strftime('%d-%m-%Y %H:%M'),
     reference,
     tracking_number,
     courier_for_client,
     items_count,
     I18n.t(is_returned),
     full_name,
     address.commune.name,
     length,
     width,
     height,
     weight,
     volume,
     volume_price,
     I18n.t(is_payable),
     I18n.t(is_paid_shipit),
     destiny,
     I18n.t(courier_selected),
     shipping_price,
     material_extra,
     total_is_payable,
     check?('out') || '',
     courier_status_updated_at,
     shipit_status_updated_at.try(:to_s),
     total_price,
     status_name(sub_status || status, courier_for_client),
     courier_status,
     I18n.t(insurance.try(:extra) || false),
     insurance.try(:ticket_amount) || 0,
     insurance.try(:ticket_number),
     insurance.try(:detail),
     insurance.try(:price) || 0,
     email]
  end
end
