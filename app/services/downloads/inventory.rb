module Downloads
  class Inventory
    attr_accessor :object, :inventories, :errors

    def initialize(object)
      @object = object[:object]
      @inventories = object[:inventories]
      @errors = []
    end

    def xlsx
      set_shipments
      generate_file
      client = ::Aws::S3::Resource.new
      bucket = client.bucket('fulfillment-inventories')
      dir = bucket.object("fulfillment-inventories/#{Time.current.year}/#{Time.current.month}/#{Time.current.day}/#{@object[:company].name} #{Time.now.strftime("%d-%m-%Y %H.%M.%S")} inventario.xlsx")
      dir.put(body: File.read("#{Rails.root}/public/xlsx/#{@object[:company].name.tr('/', '_')} Movimientos de inventario #{@object[:from_date].tr('/', '-')} - #{@object[:to_date].tr('/', '-')}.xlsx"), content_type: 'application/xlsx', acl: 'public-read')
      @object[:download].update_attributes(status: :success, downloaded: true, link: dir.public_url)

      dir.public_url
    end

    private

    def set_shipments
      @shipments = Package.where(id: @inventories.to_h.pluck(:package_id).compact)
    end

    def generate_file
      @object[:download].update!(status: :downloading)
      File.open("#{Rails.root}/public/xlsx/#{@object[:company].name.tr('/', '_')} Movimientos de inventario #{@object[:from_date].tr('/', '-')} - #{@object[:to_date].tr('/', '-')}.xlsx", 'w+b') do |f|
        data = []
        @inventories.to_h.map do |inventory|
          inventory[:inventory_activity_orders].map do |activity|
            data << spreadsheet_values(inventory, activity)
          end
        end
        f.write(SpreadsheetArchitect.to_xlsx(headers: spreadsheet_headers, data: data))
      end
    end

    def spreadsheet_headers
      temp_headers = [I18n.t('activerecord.attributes.inventory.id'),
                      I18n.t('activerecord.attributes.inventory.created_at'),
                      I18n.t('activerecord.attributes.inventory.type'),
                      I18n.t('activerecord.attributes.inventory.sku'),
                      I18n.t('activerecord.attributes.inventory.description'),
                      I18n.t('activerecord.attributes.inventory.shipment_id'),
                      I18n.t('activerecord.attributes.inventory.units'),
                      I18n.t('activerecord.attributes.inventory.total')]
    end

    def spreadsheet_values(inventory, activity)
      sku = @object[:skus].find { |sku| sku['id'] == activity[:sku_id] }
      [
        inventory[:id],
        inventory[:created_at].to_datetime.strftime('%Y/%m/%d %H:%M:%S'),
        inventory[:inventory_activity_type_id] == 2 ? 'Ingreso' : 'Egreso',
        sku.present? ? sku['name'] : nil,
        sku.present? ? sku['description']: nil,
        inventory[:package_id].present? ? @shipments.find { |s| s.id == inventory[:package_id] }.try(:reference) : nil,
        activity[:amount],
        activity[:result_stock]
      ]
    end
  end
end
