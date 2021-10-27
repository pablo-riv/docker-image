module BooticConnection
  extend ActiveSupport::Concern
  included do
    def configuration(setting = {})
      raise 'Debes ingresar una configuración' if setting.nil?
      setting.configuration['fullit']['sellers'].each do |market|
        @seller = market[@seller_name] if @seller_name == market.keys.first
      end
      return if @seller_name != 'bootic'
      BooticClient.configure do |c|
        c.client_id = @seller['client_id']
        c.client_secret = @seller['client_secret']
        c.logging = true
      end
    end

    def bootic_token(setting, authorization_token = nil)
      raise if setting.nil?
      if !authorization_token.nil?
        client = OAuth2::Client.new(ENV['BOOTIC_CLIENT_ID'], ENV['BOOTIC_CLIENT_SECRET'], site: 'https://auth.bootic.net')
        auth = client.auth_code.get_token(authorization_token)
        setting.configuration['fullit']['sellers'][1]['bootic']['access_token'] = auth.token
        setting.update_columns(configuration: setting.configuration)
      else
        access_token = setting.configuration['fullit']['sellers'][1]['bootic']['access_token']
        BooticClient.client(:authorized, access_token: access_token) do |new_token|
          setting.configuration['fullit']['sellers'][1]['bootic']['access_token'] = new_token
          setting.update_columns(configuration: setting.configuration)
        end
      end
      setting.configuration['fullit']['sellers'][1]['bootic']['access_token']
    end

    def download_bootic(setting)
      token = bootic_token(setting)
      raise 'Sin Token' if token.nil?
      bootic = BooticClient.client(:authorized, access_token: token, logging: true)
      bootic.root.shops.each do |shop|
        puts "Tienda: #{shop.name}".yellow
        shop.orders({status: 'closed', per_page: 400, sort: 'created_on.desc'}).items.each do |order|
          incomplete = false
          items = order.entities[:line_items].map { |li| li.blank? ? (incomplete = true) : li.properties }
          next if incomplete || order.blank? || order.entities[:address].blank? || order.entities[:contact].blank?
          address = order.entities[:address].properties
          contact = order.entities[:contact].properties
          order = order.properties.merge(company_id: setting.company_id,
                                         seller: 'bootic',
                                         address: address,
                                         contact: contact,
                                         items: items)
          order[:order_id] = order[:id]
          order = order.except(:id)
          find_or_create_order(hash_format(order))
        end
      end
    end

    def update_bootic_order(order, package, setting = nil)
      if package.status == 'delivered'
        package.status = 'in_route'
        update_bootic_order(order, package, setting)
        package.status = 'delivered'
      end
      status =
        case package.status
        when 'in_route' then 'shipped'
        when 'delivered' then 'delivered'
        end
      status = 'shipped' if status.blank? && !package.tracking_number.blank?
      return if status.blank? || package.tracking_number.blank?
      token = bootic_token(setting)
      bootic = BooticClient.client(:authorized, access_token: token, logging: true)
      bootic.root.shops.each do |shop|
        bootic_order = shop.orders({code: order.code}).items.first
        next if bootic_order.nil?
        params = {
          tracking_code: package.tracking_number,
          courier_name: package.courier_for_client.try(:capitalize),
          status: status
        }
        bootic_order.update_order_tracking(params)
      end
    end
  end
end
