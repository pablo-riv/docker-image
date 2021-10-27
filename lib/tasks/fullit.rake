namespace :fullit do
  desc 'Add fullit to all companies'
  task add_companies: :environment do
    logs = []
    Company.all.each do |company|
      fullit = Setting.fullit(company.id)
      logs <<
        if fullit.present?
          "😎 #{company.name} has FULLIT active".yellow
        else
          company.settings.create(service_id: 2)
          "😎 Now #{company.name} has FULLIT active".green
        end
    end
    logs.each { |l| puts l }
  end

  desc 'Migrate all orders and do match with their packages'
  task orders: :environment do
    data = JSON.parse(File.read("#{Rails.root}/lib/data/fullit_orders.json"))
    data['data'].each do |order|
      company = order['company_id'] == 2 ? Company.find(225) : Company.find(16)
      puts 'buscando package...'
      package = Package.unscoped.where(id: order['package_id'].try(:to_i)).first
      next unless company.present? && package.present?
      setting = Setting.fullit(company.id)
      client_id = setting.configuration['fullit']['sellers'][0]['dafiti']['client_id']
      client_secret = setting.configuration['fullit']['sellers'][0]['dafiti']['client_secret']
      puts 'configurando...'
      marketplace = SellerConnection.new('dafiti', client_id, client_secret)
      puts 'descargando orden...'
      marketplace.dafiti_single_order(order['order_id'], company.id)
      backup_order = OrderService.find_by(order_id: order['order_id'])
      next unless backup_order.present?
      puts 'actualizando orden y package...'
      backup_order.update_attributes(statuses: { status: order['status'] }, sent: true, package_id: package.id)
      package.update_columns(mongo_order_id: backup_order.id.to_s)
      puts 'finalizado'
    end
  end

  desc 'Change sended param for sent cz it is gramatically incorrent at the beginning'
  task change_sended: :environment do
    OrderService.all.each do |os|
      os.update_attributes(sent: os.sended) if os.respond_to?(:sended)
      os.update_attributes(sent_at: os.sended_at) if os.respond_to?(:sended_at)
    end
  end


  desc 'Loop companies and send orders if it is configured so'
  task send_orders: :environment do
    cos = Company.all.select { |w| w.any_integrations? }
    cos.each do |company|
      setting = Setting.fullit(company.id)
      puts "Consultando configuración de #{company.name}"
      next if setting.blank? || setting.configuration.blank? || setting.configuration['fullit'].blank? || setting.configuration['fullit']['sellers'].blank?
      setting.configuration['fullit']['sellers'].each do |integration|
        current_account = company.accounts.first
        integrations = company.integrations_activated

        integration.each do |name, config|
          next unless integrations.include?(name)
          puts "procesando #{name}"

          next if (config['client_id'].blank? && name != 'bootic') || (name == 'bootic' && config['authorization_token'].blank?)
          next if config['automatic'].blank? || !(config['automatic'].to_s == 'true')
          next if config['automatic_hour'].blank? || !(0..300).cover?(Time.current - config['automatic_hour'].to_time)

          automatic_packing = config['automatic_packing'].to_time unless config['automatic_packing'].blank?
          box_type = automatic_packing.blank? ? 'Sin empaque' : automatic_packing

          marketplace = SellerConnection.new(name, config['client_id'], config['client_secret'], config['store_name'])
          marketplace.download_packages_from(setting, name)
          setting_fulfillment = current_account.current_company.services.find_by(name: 'fulfillment')
          sku_client = FulfillmentService.by_client(current_account.current_company.id) if setting_fulfillment.present?

          package_results = OrderService.where(company_id: company.id, sent: false, seller: name).map do |order|
            puts "sending order: #{order.order_id}".green
            params = { order_id: order.order_id,
                       box_type: box_type,
                       current_account: current_account,
                       skus: sku_client,
                       has_fulfillment: setting_fulfillment }
            OrderService.deliver_order(params) unless order.commune.blank?
          end
          packages = package_results.select { |result| result if result.class.name == 'Package' }.select { |package| package unless package.same_day_delivery? }.compact
          #Publisher.publish('mass', Package.generate_template_for(3, packages, current_account)) unless setting_fulfillment.present?
          puts "#{seller} procesado"
        end
      end
    end
  end

  desc 'Download Massive'
  task download_massive: :environment do
    Company.all.each do |company|
      Setting.fullit(company.id).sync_seller_orders
    end
  end

  desc 'Disconnect Unactives api2cart stores'
  task download_massive: :environment do
    Company.where("created_at < ?", Date.civil(2018, 12, 1)).map do |w|
      next unless w.packages.where("packages.created_at::date > ?", Date.civil(2018,12,1)).size.zero?
      xx = w.integrations_activated
      next unless xx.include?('prestashop') || xx.include?('woocommerce')
      # begin
      #   api_key = '9eafdd708335342240c20c5a4ee7c7e7'
      #   setting = Setting.fullit(w.id)
      #   if xx.include?('prestashop')
      #     store_key = setting.seller_configuration('prestashop')['prestashop']['client_secret']
      #     url_composer = Api2cart::RequestUrlComposer.new(api_key, store_key, 'cart_delete', {})
      #     client = Api2cart::Client.new(url_composer.compose_request_url)
      #     puts client.make_request!
      #   end
      #   if xx.include?('woocommerce')
      #     store_key = setting.seller_configuration('woocommerce')['woocommerce']['client_secret']
      #     url_composer = Api2cart::RequestUrlComposer.new(api_key, store_key, 'cart_delete', {})
      #     client = Api2cart::Client.new(url_composer.compose_request_url)
      #     puts client.make_request!
      #   end
      # rescue => e
      #   puts e.message
      #   next
      # end
      puts w.name
      w.id
    end
  end



end
