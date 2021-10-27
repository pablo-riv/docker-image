module Downloads
  class Sku
    attr_accessor :object, :skus, :errors

    def initialize(object)
      @object = object[:object]
      @skus = object[:skus]
      @errors = []
    end

    def xlsx
      generate_file
      client = ::Aws::S3::Resource.new
      bucket = client.bucket('fulfillment-inventories')
      dir = bucket.object("fulfillment-inventories/#{Time.current.year}/#{Time.current.month}/#{Time.current.day}/#{@object[:company].name} #{Time.now.strftime("%d-%m-%Y %H.%M.%S")} SKUs.xlsx")
      dir.put(body: File.read("#{Rails.root}/public/xlsx/#{@object[:company].name.tr('/', '_')} SKUs.xlsx"), content_type: 'application/xlsx', acl: 'public-read')
      @object[:download].update_attributes(status: :success, downloaded: true, link: dir.public_url)

      dir.public_url
    end

    private

    def generate_file
      @object[:download].update!(status: :downloading)
      File.open("#{Rails.root}/public/xlsx/#{@object[:company].name.tr('/', '_')} SKUs.xlsx", 'w+b') do |f|
        data = []
        @skus.map do |sku|
          data << spreadsheet_values(sku.to_h)
        end
        f.write(SpreadsheetArchitect.to_xlsx(headers: spreadsheet_headers, data: data))
      end
    end

    def spreadsheet_headers
      temp_headers = [I18n.t('activerecord.attributes.sku.id'),
                      I18n.t('activerecord.attributes.sku.name'),
                      I18n.t('activerecord.attributes.sku.description'),
                      I18n.t('activerecord.attributes.sku.created_at'),
                      I18n.t('activerecord.attributes.sku.height'),
                      I18n.t('activerecord.attributes.sku.width'),
                      I18n.t('activerecord.attributes.sku.length'),
                      I18n.t('activerecord.attributes.sku.weight'),
                      I18n.t('activerecord.attributes.sku.amount_available')]
    end

    def spreadsheet_values(sku)
      [
        sku[:id],
        sku[:name],
        sku[:description],
        sku[:created_at].to_datetime.strftime('%Y/%m/%d %H:%M:%S'),
        sku[:height],
        sku[:width],
        sku[:length],
        sku[:weight],
        sku[:amount]
      ]
    end
  end
end
