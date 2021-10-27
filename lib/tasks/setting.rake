namespace :setting do

  desc 'Run setters for old orders'
  task update_old_orders: :environment do
    OrderService.all.each { |order|
      order.set_seller_reference
      order.set_customer_name
      order.set_customer_email
      order.set_customer_phone
      order.set_shipping_data
      order.set_shipping_data_complement
      order.set_commune }
  end

  desc 'Generate printers setting to all companies'
  task printers: :environment do
    Company.all.each { |company| company.settings.create(service_id: 7) }
  end

  desc 'Add new format to printers configuration'
  task update_printers: :environment do
    Setting.where(service_id: 7).find_each(batch_size: 100).each do |setting|
      configuration = setting.configuration
      configuration['printers']['formats'] << { format: 5292,
                                                sizes: '4x6',
                                                quantity: 1,
                                                name: 'avery',
                                                img: '/assets/avery/5292.png',
                                                display: '1x1' }
      setting.update_columns(configuration: configuration)
    end
  end

  desc 'Update printers format configuration'
  task update_printer_formats: :environment do
    Setting.where(service_id: 7).find_each(batch_size: 100).each do |setting|
      configuration = setting.configuration
      configuration['printers']['availables'].map do |f|
        next unless f['name'] == 'zpl'

        f['format'] = 'zpl'
        f
      end
      setting.update_columns(configuration: configuration)
    end
  end

  desc 'Update printers configuration'
  task update_printer_formats: :environment do
    Setting.where(service_id: 7).find_each(batch_size: 100).each do |setting|
      configuration = setting.configuration
      configuration['printers']['label_package_size'] = '4x4'
      setting.update_columns(configuration: configuration)
    end
  end

  desc 'update configurations with notification for existing accounts'
  task configuration_update: :environment do
    companies = Company.all

    companies.each do |company|
      company.settings.create(service_id: 6) unless Setting.notification(company.id)
    end
  end

  desc 'update pick and pack configuration'
  task add_sandbox: :environment do
    logs = []
    Setting.where(service_id: 3).each do |setting|
      setting.configuration = { 'pp' => { 'key' => '', 'secret_key' => '', 'price' => '', 'sandbox' => false } }
      logs <<
        if setting.update_columns(configuration: setting.configuration)
          "Company: #{setting.company.name} with sandbox parameter".green.swap
        else
          "Company: #{setting.company.name} without sandbox parameter".red.swap
        end
    end
    logs.each { |l| puts l }
  end

  desc 'Add couriers preferred by clients to opit config as json'
  task add_preferred_couriers_to_opit_setting: :environment do
    Company.all.map { |c| c.settings.create(service_id: 1) unless Setting.opit(c.id) }
    Setting.where(service_id: 1).each do |setting|
      con = setting.configuration
      con['opit']['couriers'].each { |courier| courier.values.first['available'] = true if courier.values.first['available'].blank? }
      setting.update_columns(configuration: con)
    end
  end

  desc 'Adding alerts of packages price too high for clients'
  task add_alert_of_package_too_high: :environment do
    Setting.where(service_id: 6).each do |setting|
      conf = setting.configuration
      next if conf.blank? || conf['notification'].blank?
      conf['notification']['client']['order_to_high'] = { 'enable' => true, 'amount' => 50_000 }
      setting.update_columns(configuration: conf)
    end
  end

  desc 'Add analytics service to companies'
  task analytics: :environment do
    analytics_service = Service.find_by(name: 'analytics')
    if analytics_service.blank?
      analytics_service = Service.create(name: 'analytics')
    end
    Company.all.map { |company| company.settings.create(service_id: analytics_service.id) unless company.settings.find_by(service_id: analytics_service.id) }
  end

  desc 'Send weekly scheduled report'
  task scheduled_weekly_report: :environment do
    Setting.where(service_id: 8).find_each(batch_size: 20).each do |setting|
      company = setting.company
      next unless company.present?

      account = company.default_account
      conf = setting.configuration['analytics']
      next unless conf['active_mailer'] && conf['available'] && conf['send_period'] == 'weekly'

      next unless case Time.now.strftime('%A')
                  when 'Monday' then (conf['days'] == 'monday' || conf['days'] == 'monday_friday')
                  when 'Friday' then (conf['days'] == 'friday' || conf['days'] == 'monday_friday')
                  else false
                  end

      analytics = AnalyticsController.new
      dates = analytics.set_dates(conf['analytics_period'], Date.current.strftime('%d/%m/%Y'))
      analytics_service = AnalyticsService.new(date: dates,
                                                company: company,
                                                account: account)
      data = analytics_service.process
      emails = conf['emails'].split(',').map(&:strip)
      AnalyticsMailer.analytics(emails, data).deliver_now
    end
  end

  desc 'Send monthly scheduled report'
  task scheduled_monthly_report: :environment do
    Setting.where(service_id: 8).find_each(batch_size: 20).each do |setting|
      company = setting.company
      account = company.default_account
      conf = setting.configuration['analytics']
      next unless conf['active_mailer'] && conf['available'] && conf['send_period'] == 'monthly'
      analytics = AnalyticsController.new
      dates = analytics.set_dates(conf['analytics_period'], Date.current.strftime('%d/%m/%Y'))
      analytics_service = AnalyticsService.new(date: dates,
                                               company: company,
                                               account: account)
      data = analytics_service.process
      emails = conf['emails'].split(',').map(&:strip)
      AnalyticsMailer.analytics(emails, data).deliver_now
    end
  end

  task default_notification: :environment do
    Setting.where(service_id: 6).each do |setting|
      notifications = setting.default_template_notification
      setting.update_columns(configuration: notifications)
    end
  end

  task update_notification: :environment do
    Setting.where(service_id: 6).each do |setting|
      company = Company.find_by(id: setting.company_id)
      olds = setting.configuration['notification']
      notifications = {
        notification: {
          client: {
            pickup: olds['pickup'],
            state: {
              in_preparation: olds['to_buyer'],
              failed: olds['failed']
            },
            order_to_high: { enable: olds['order_to_high']['enable'], amount: olds['order_to_high']['amount'] },
            fulfillment: { broke_stock: false, security_stock: false, email: '' }
          },
          buyer: {
            state: {
              in_preparation: olds['to_buyer'],
              in_route: olds['to_buyer'],
              by_retired: olds['to_buyer'],
              delivered: olds['to_buyer'],
              failed: olds['to_buyer']
            }
          }
        }
      }
      if company.fulfillment?
        notifications[:notification][:client][:fulfillment] = { broke_stock: olds['fulfillment']['broke_stock'],
                                                                security_stock: olds['fulfillment']['security_stock'],
                                                                email: olds['fulfillment']['email'] }
      end
      company.generate_default_buyer_emails if setting.update_columns(configuration: notifications)
    end
  end

  desc 'Add cc to buyer state email'
  task add_cc: :environment do
    Setting.where(service_id: 6).each do |setting|
      company = setting.company
      next unless company.present?

      if setting.configuration['notification']['buyer']['state'].present?
        in_preparation = setting.configuration['notification']['buyer']['state']['in_preparation']
        in_route = setting.configuration['notification']['buyer']['state']['in_route']
        by_retired = setting.configuration['notification']['buyer']['state']['by_retired']
        delivered = setting.configuration['notification']['buyer']['state']['delivered']
        failed = setting.configuration['notification']['buyer']['state']['failed']
      else
        in_preparation = setting.configuration['notification']['buyer']['mail']['state']['in_preparation']
        in_route = setting.configuration['notification']['buyer']['mail']['state']['in_route']
        by_retired = setting.configuration['notification']['buyer']['mail']['state']['by_retired']
        delivered = setting.configuration['notification']['buyer']['mail']['state']['delivered']
        failed = setting.configuration['notification']['buyer']['mail']['state']['failed']
      end

      setting.configuration['notification']['buyer'].delete_if { |b| b['state'] }
      setting.configuration['notification']['buyer'] = {
        mail: {
          cc: company.current_account.try(:email),
          state: {
            in_preparation: { active: in_preparation, cc: false },
            in_route: { active: in_route, cc: false },
            by_retired: { active: by_retired, cc: false },
            delivered: { active: delivered, cc: false },
            failed: { active: failed, cc: false }
          }
        }
      }
      setting.save
    end
  end

  desc 'Change webhooks structure'
  task change_webhook_structure: :environment do
    Setting.where(service_id: 3, company_id: 1).each do |setting|
      packages_url = setting.configuration['pp']['packages_webhook_url']
      pickups_url = setting.configuration['pp']['pickups_webhook_url']
      setting.configuration['pp']['webhook'] = {
        package: { url: packages_url, options: { sign_body: { required: false, token: '' }, authorization: { required: false, kind: 'Basic', token: '' } } },
        pickup: { url: pickups_url, options: { sign_body: { required: false, token: '' }, authorization: { required: false, kind: 'Basic', token: '' } } }
      }
      setting.update_columns(configuration: setting.configuration)
    end
    Setting.where(service_id: 4).each do |setting|
      sku_url = setting.configuration['fulfillment']['skus_webhook_url']
      setting.configuration['fulfillment']['webhook'] = {
        sku: { url: sku_url, options: { sign_body: { required: false, token: '' }, authorization: { required: false, kind: 'Basic', token: '' } } }
      }
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Migrate all seller configuration'
  task update_integration: :environment do
    attributes = { 'automatic_delivery' => false, 'show_shipit_checkout' => true }
    Setting.where(service_id: 2).each do |setting|
      setting.configuration['fullit']['sellers'].map do |seller|
        seller[seller.keys[0]].merge!(attributes)
      end
      Setting.where("service_id = 2 and configuration -> 'fullit' -> 'sellers' -> '8' -> 'vtex' is null")
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Migrate all seller configuration for checkout'
  task update_integration_checkout: :environment do
    Setting.where(service_id: 2).each(&:create_or_update_checkout)
  end

  desc 'migrate attribute'
  task migrate_bootic: :environment do
    Setting.where(service_id: 2).each do |setting|
      setting.configuration['fullit']['sellers'].map do |seller|
        next unless seller.keys.first == 'bootic'

        seller[seller.keys.first]['authorization_token'] = seller[seller.keys.first]['autorization_token']
        seller[seller.keys.first].delete_if { |k, _v| k == 'autorization_token' }
      end
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Add vtex seller configuaration'
  task add_vtex: :environment do
    # Setting.where("service_id = 2 and configuration -> 'fullit' -> 'sellers' -> '8' -> 'vtex' is null")
    Setting.where(service_id: 2).each do |setting|
      vtex = setting.configuration['fullit']['sellers'].find { |s| s[s.keys[0]] == 'vtex' }

      next if vtex.present?

      setting.configuration['fullit']['sellers'] << { vtex: { client_id: '', client_secret: '', automatic_delivery: false, show_shipit_checkout: true, store_name: '' } }
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Add whatsapp to notification setting'
  task add_whatsapp: :environment do
    Setting.where(service_id: 6).each do |setting|
      configuration = setting.configuration
      whatsapp = {
        whatsapp: {
          state: {
            in_preparation: { active: false },
            in_route: { active: false },
            by_retired: { active: false },
            delivered: { active: false },
            failed: { active: false }
          }
        }
      }
      configuration['notification']['buyer'].merge!(whatsapp)
      setting.update_columns(configuration: configuration)
    end
  end

  desc 'Task to update suite printer option'
  task change_printer_default: :environment do
    Setting.where("service_id = 7 AND configuration -> 'printers' ->> 'kind_of_print' <> 'print_node'").each do |setting|
      setting.configuration['printers']['availables'] = [{ active: true, format: 'zpl', provider: 'WEB_BROWSER', sizes: '4x4', quantity: 1, name: 'zpl', img: 'https://printer-labels.s3-us-west-2.amazonaws.com/ST/2018/4/2/pack_296886__02_04_2018__912023401.pdf' }]
      setting.configuration['printers']['kind_of_print'] = 'download'
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'include version'
  task include_version_to_integration: :environment do
    Setting.where(service_id: 2).each do |setting|
      setting.configuration['fullit']['sellers'].map do |seller|
        seller[seller.keys[0]]['version'] = %w[woocommerce prestashop].include?(seller.keys.first) ? 2 : 1
      end

      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Deactivate failed notification to all customer and buyers'
  task deactivate_failed: :environment do
    Setting.where(service_id: 6).each do |setting|
      begin
        configuration = setting.configuration
        configuration['notification']['buyer']['mail']['state']['failed']['active'] = false
        configuration['notification']['buyer']['whatsapp']['state']['failed']['active'] = false
        configuration['notification']['client']['state']['failed'] = false
        setting.update_columns(configuration: configuration)
      rescue => e
        puts e.message
      end
    end
  end

  desc 'bulk fullit data'
  task bulk_fullit: :environment do
    data = { data: [] }
    Setting.where(service_id: 2).each do |setting|
      data[:data] << { company_id: setting.company_id, configuration: setting.configuration }.to_json
    end
    File.open("#{Rails.root}/lib/data/fullit.json", 'wb') do |file|
      file.write(data.to_json)
    end
  end

  desc 'migrate shopify v2'
  task migrate_shopify: :environment do
    logs = []
    emails = ['jonovoa@uc.cl', 'shipit@shipit.cl', 'irios@bestias.cl', 'fclaro@creadoenchile.cl', 'contacto@herbatint.cl', 'compras@kayaunite.com', 'gthadaney@jpt.cl', 'piero@hovercamera.cl', 'fsanzana@gmail.com', 'cperez@ryk.cl', 'piero@promixx.cl', 'contacto@monparfum.cl', 'mpastaburuaga@gmail.com', 'scordova@chantilly.cl', 'cristobal.galilea@touchsmart.cl', 'contacto@greenutrition.cl', 'fmoralesl@gmail.com', 'pedropablo.es@gmail.com', 'contacto@froens.cl', 'ceblen@scorpi.cl', 'contacto@rideshop.cl', 'info@pontetu.cl', 'nico@simpleyvivo.com', 'francisco.diaz@tendenciasgourmet.cl', 'karen.meyer@medihealchile.com', 'tienda@ibyk.cl', 'mldesignchile@gmail.com', 'santiago@biowell.cl', 'ventasmkp@ldp.cl', 'contacto@entrehermanos.cl', 'paola.gorriateguy@gmail.com', 'ventas@mrclick.cl', 'asistente@primeretail.cl', 'info@sweetea.cl', 'hola@papeldejengibre.cl', 'corbataspalmatri@gmail.com', 'fractales3d@gmail.com', 'cgiglio@biobrush.cl', 'ignacio.pommerenke@gmail.com', 'aleon.oliva@gmail.com', 'inversioneslazchile@gmail.com', 'webmaster@zensativa.cl', 'beavergara@gmail.com', 'francisca@zapallito.cl', 'gaelle@tessachile.com', 'info@karyncoo.com', 'gramirez.e@gmail.com', 'rodrigoburgoscl@gmail.com', 'cata@lasebastianazapateria.cl', 'info@shopmai.cl', 'adonoso@gobuy.cl', 'inversioneslazchile@gmail.com', 'contacto@double-vision.cl', 'terewinter@microchile.cl', 'hola@eciclos.cl', 'emiliano@tecathlon.com', 'egidio.hernandez@monkeycolor.cl', 'fvymazal@pichintuntienda.cl', 'contacto@thewomansplace.cl', 'ventas@rosabergamota.cl', 'ventas@jacintatienda.cl', 'macarena@fashiontoys.cl', 'jurrutia@detogni.cl', 'fhlazog@gmail.com', 'contacto@daikiri.cl', 'moises@grupoyeschile.cl', 'despachos@easyways.cl', 'info@cellskinlab.com', 'raul.delvalle@bydeluxe.cl', 'r.naranjo@powerperalta.cl', 'havanawebcl@gmail.com', 'mariangelica@moraleja.cl', 'lanacionalgranel@gmail.com', 'daniel@bodyoptimizer.cl', 'contacto@cadacosaensulugar.cl', 'contacto@makeplace.cl', 'vomerchile@gmail.com', 'zach@lenteseclipse2019.com', 'info@naturbaby.cl', 'operaciones@denda.cl', 'produccion@subela.cl', 'sistemas@essentialstore.cl', 'e-commerce@benexia.com', 'nblanch_27@hotmail.com', 'felipe@sikbrands.com', 'danimonac@gmail.com', 'maikasnacks@gmail.com', 'josefina@urco.cl', 'contacto@yerqui.cl', 'tiendaonline@kaikai.cl', 'gabriel@greenfood.cl', 'contacto@marca2.cl', 'administracion@picaflor.cl', 'amthauer@hotmail.com', 'cretamal@miaguitta.cl', 'emilio@comercialdual.cl', 'a.salazar@mbmlatam.cl', 'diffonchile@gmail.com', 'hola@pintoatupinta.com', 'yo@karina.cl', 'contacto@ludusmd.cl', 'businessforlatam@skyfox.cl', 'apower@laforett.com', 'chumango@gmail.com', 'gina@australorganics.cl', 'carlapoblete2@gmail.com', 'mmartinez.sales@gmail.com', 'contacto@mspa.cl', 'mpasaron@molychile.cl', 'joaquin.marsalc@gmail.com', 'rodrigo@lookb.cl', 'paula.diaz@kenmore.cl', 'contacto@vitrineate.cl', 'ventas@mundomiel.com', 'esteban.marambio@gmail.com', 'pregunta@kooh.cl', 'paulamar.chile@gmail.com', 'ana@drava.cl', 'contacto@mspa.cl', 'cafe2d6@gmail.com', 'loredana.benitez@arte59.cl', 'hectorcisternasm@hotmail.com', 'hola@therevelaine.com', 'mateo@cascarafoods.com', 'nicoaguilera80@gmail.com', 'lpoperaciones@logisticplus.cl', 'despachos@luaushoes.cl', 'comercial@malldelparrillero.cl', 'contacto@simplenutricion.cl', 'himalayarincon@gmail.com', 'abriones@partyexpress.cl', 'mariajose@thedecojournal.com', 'javier.ayelli@unicus.cl', 'aldomartinschile@gmail.com', 'loreto.klein@boketo.cl', 'dollyblankets1@gmail.com', 'robert@htrendy.cl', 'damian@rumbos.cl', 'lafeartesanias@gmail.com', 'dwurman@induropa.com', 'david@slapstore.cl', 'paula.diaz@kenmore.cl', 'info@alquimiaespiritual.cl', 'carlos@studiomusic.cl', 'deepak@theperfumeshop.cl', 'rgoklani@gmail.com', 'deepak@saideep.cl', 'contacto@spacestore.cl', 'ventas@elruco.cl', 'ffernandez@davis.cl', 'ssoza@innovate-k.cl', 'kike@signoremario.com', 'pangeacosmeticschile@gmail.com', 'ventas@alishaperfumes.cl', 'ventas@alishaperfumes.cl', 'compras@lpk.cl', 'cwerner@centralturbos.cl', 'jmoyano@divinamama.cl', 'ivanolguinr@yahoo.com', 'ventas@lujoymas.cl', 'ventas@productosdelujo.cl', 'hola@atar.cl', 'martin.sigren96@gmail.com', 'struansa@gmail.com', 'contacto@neoenesquemas.cl', 'visionshop.chile@gmail.com', 'ventas@outletdefragancias.cl', 'ventas@originalperfumes.cl', 'dfuentes@gbf.cl', 'yei.leggings@gmail.com', 'ssoza@innovate-k.cl', 'francisco.arenas@shipit.cl', 'contacto@pageone.cl', 'francisco.arenas@shipit.cl', 'ventas@eclipsechile.com', 'contacto@e-marco.com', 'fernando.abarca.martinez@gmail.com', 'contacto@dolcenatura.cl', 'camilakovacevicw@gmail.com', 'hola@petfy.cl', 'oc@blancayaugusto.cl', 'admlibreriaperiferica@gmail.com', 'contacto@lafabricastore.cl', 'hola@milibone.com', 'pedidos@ludovica.cl', 'storedevastation@gmail.com', 'yasmin.navarro@maikra.cl', 'soporte@bakkan.cl', 'vishalaks2005@hotmail.com', 'sonia@titimio.com', 'deepak@fraganzza.cl', 'olayaarraztoa@getawaybox.cl', 'contacto@amanuta.cl', 'ricardo@vamosagenciadigital.cl', 'staff@shipit.cl']
    Account.where(email: emails).each do |account|
      company = account.current_company
      next unless company.present?

      setting = Setting.fullit(company.id)
      setting.configuration['fullit']['sellers'].map do |seller|
        next unless seller.keys.first == 'shopify'
        next if seller['shopify']['client_id'].present? && seller['shopify']['client_secret'].present? && seller['shopify']['store_name'].present?

        seller['shopify']['client_id'] = account.email
        seller['shopify']['client_secret'] = account.authentication_token
        seller['shopify']['version'] = 2

        logs << "CLIENTE: #{company.name} MIGRADO A V2".green.swap
        seller
      end

      setting.update_columns(configuration: setting.configuration)
    end
    logs.each { |l| puts l }
  end

  task update_shopify_webhook: :environment do
    Setting.where(service_id: 2).each do |fullit|
      begin
        sellers = fullit.sellers_availables
        next if sellers.empty?

        shopify = sellers.find { |seller| seller.keys.first == 'shopify' }

        next unless shopify.present?
        next if shopify['version'] == 1

        webhook = Setting.pp(fullit.company_id)
        company = fullit.company
        puts "COMPANY: #{company.name} WILL UPDATE SHOPIFY WEBHOOK".yellow.swap
        current_account = company.current_account
        webhook.configuration['pp']['webhook']['package']['url'] = "https://shopify.shipit.cl/webhooks?api_key=#{current_account.authentication_token}"
        webhook.update_columns(configuration: webhook.configuration)
      rescue => e
        binding.pry
      end
    end
  end

  desc 'populate all new_algorithm prices to rollout'
  task new_prices_algorithm_indicator: :environment do
    Setting.where(service_id: 1).find_each(batch_size: 30) do |setting|
      next unless setting.company.present?

      setting.configuration['opit']['courier_prices_v3_enabled'] = false
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Add rut and dv for every couriers base config'
  task rut_for_couriers_tcc: :environment do
    Setting.where(service_id: 1).find_each(batch_size: 30) do |setting|
      conf = setting.configuration
      next if conf['opit'].blank? || conf['opit']['couriers'].blank?

      conf['opit']['couriers'].each do |courier_conf|
        courier_conf.values.first['rut'] = '76499449'
        courier_conf.values.first['dv'] = '3'
      end
      setting.update_columns(configuration: conf)
    end
  end

  desc 'Add automatization service to companies'
  task set_automatizations: :environment do
    automatization = Service.find_by(name: 'automatizations')
    if automatization.blank?
      automatization = Service.create(name: 'automatizations')
    end
    Company.all.map { |company| company.settings.create(service_id: automatization.id) unless company.settings.find_by(service_id: automatization.id) }
  end

  desc 'Enable courier for csv company repo'
  task :enable_courier, [:courier] => :environment do |_t, args|
    puts "ENABLE COURIER #{args[:courier]}".green.swap
    csv = File.read("#{Rails.root}/lib/data/#{args[:courier]}_activate.csv")
    CSV.parse(csv, headers: true).each_with_index do |data, _index|
      data = data.to_hash.with_indifferent_access
      opit = Setting.opit(data[:id].to_i)
      puts 'opit not found'.red.swap && next unless opit.present?

      opit.configuration['opit']['couriers'].map do |courier|
        next unless courier.keys.first == args[:courier]

        courier[courier.keys.first]['available'] = true
      end
      puts "ENABLE COURIER #{args[:courier]} FOR COMPANY #{opit.company.try(:name)}".yellow.swap
      opit.update_columns(configuration: opit.configuration)
    end
    puts "ENABLED COURIER #{args[:courier]}".green.swap
  end

  desc 'Migrate all integration with default rates'
  task add_rate_to_integration: :environment do
    attributes = {
      show_rate: true,
      rates: Rails.configuration.integration[:checkout][:rates].with_indifferent_access
    }.with_indifferent_access

    Setting.where(service_id: 2).each do |setting|
      setting.configuration['fullit']['sellers'].map do |seller|
        begin
          seller[seller.keys[0]]['checkout'].merge!(attributes)
        rescue NoMethodError => e
          puts "COMPANY: #{setting.company.name} - ERROR: #{e.message}".red.swap
          seller[seller.keys[0]]['checkout'] = Rails.configuration.integration[:checkout].with_indifferent_access
        end
      end
    end
  end

  desc 'Add icon to Shippify'
  task shippify_icon: :environment do
    Setting.where(service_id: 1).each do |setting|
      setting.configuration['opit']['couriers'].map do |courier|
        next unless courier.keys.first == 'shippify'

        courier[courier.keys.first]['icon'] = 'https://s3.us-west-2.amazonaws.com/couriers-shipit/shippify.png'
      end
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Remove dhl and cc from settings'
  task remove_couriers_from_configuration: :environment do
    puts 'Init process'.green
    puts '======================================='.green
    Setting.where(service_id: 1).each do |setting|
      configuration = setting.configuration
      puts "#{setting.configuration['opit']['couriers'].map { |courier| courier.keys }.flatten}".red
      configuration['opit']['couriers'].reject! { |courier| courier['cc'] || courier['dhl'] }
      setting.update_columns(configuration: configuration)
      puts "#{setting.configuration['opit']['couriers'].map { |courier| courier.keys }.flatten}".blue
    end
  end

  desc 'Add backoffice couriers flag in opit configuration from companies'
  task add_backoffice_couriers_flag: :environment do
    puts 'Init process'.green
    puts '======================================='.green
    Setting.where(service_id: 1).each do |setting|
      next unless setting.company.present?

      setting.configuration['opit']['is_backoffice_couriers_enabled'] = false
      setting.update_columns(configuration: setting.configuration)
    end
    puts '======================================='.green
    puts 'Finished process'.green
  end

  desc 'Add sizes and renaming magento field'
  task :add_sizes_and_renaming_magento, [:company_ids] => :environment do |_t, args|
    company_ids = args[:company_ids] ? args[:company_ids] : Company.all.pluck(:id)
    magento_conf = {
      store_name: '',
      store_base_url: '',
      sizes: {
        length: 10,
        height: 10,
        width: 10,
        weight: 1
      }
    }
    Setting.where(
      company_id: company_ids,
      service_id: Service.find_by(name: 'fullit').try(:id)
    ).each do |setting|
      configuration = setting.configuration
      seller_conf = configuration['fullit']['sellers'].map do |seller|
        if seller['magento_one']
          seller['magento_one'].merge!(magento_conf)
          seller['magento'] = seller['magento_one']
          seller.delete('magento_one')
        end
        seller
      end
      configuration['fullit']['sellers'] = seller_conf
      setting.update_columns(configuration: configuration)
    end
  end

  desc 'Add automatic delivery and next day to same day config'
  task add_automatic_delivery_and_next_day_to_sdd: :environment do
    same_day_conf = {
      automatic_delivery: true,
      next_day: false
    }
    Setting.by_service(2).find_each(batch_size: 50) do |setting|
      setting.configuration['fullit']['sellers'].map do |seller|
        seller[seller.keys[0]]['same_day'].merge!(same_day_conf)
      end
      setting.update_columns(configuration: setting.configuration)
    end
  end

  desc 'Add new courier setting template by courier name'
  task :add_new_courier_setting_template, [:courier_name, :country_acronym] => :environment do |_t, args|
    puts 'Init process'.green
    puts '======================================='.green
    courier_name = args[:courier_name].try(:downcase)
    country_acronym = args[:country_acronym].try(:downcase)
    return puts "Nombre de courier '#{courier_name}' inválido" unless courier_name.present?

    errors = []
    settings = Setting.where(service_id: 1)
    counter = 1
    total_amount = settings.size
    settings.each do |setting|
      begin
        puts "Progress #{counter}/#{total_amount}".yellow
        puts "Setting ID: #{setting.try(:id)} starting".cyan
        next errors << setting.id unless setting.company.present?

        configuration = setting.configuration
        new_courier_template = { courier_name => setting.current_template_couriers(courier_name, country_acronym) }
        same_courier_configuration = configuration['opit']['couriers'].find { |courier| courier[courier_name] }
        if same_courier_configuration.present?
          puts 'Setting with courier configuration already present'.yellow
          counter += 1
          next
        end

        configuration['opit']['couriers'].push(new_courier_template)
        setting.update_columns(configuration: configuration)
        puts "Setting ID: #{setting.try(:id)} updated successfully".green
        counter += 1
      rescue StandardError => e
        puts "Error: #{e.message}".red
        errors << setting.id
        counter += 1
      end
    end
    puts errors.join("\n")
    puts '======================================='.green
    puts 'Finished process'.green
  end

  desc 'Add algorithm field to fullit config'
  task :add_algorithm_to_fullit, [:company_ids] => :environment do |_t, args|
    company_ids = args[:company_ids].presence || Company.all.ids
    Setting.where(
      company_id: company_ids,
      service_id: Service.find_by(name: 'fullit').try(:id)
    ).each do |setting|
      configuration = setting.configuration
      seller_conf = configuration['fullit']['sellers'].map do |seller|
        seller[seller.keys[0]]['checkout'].merge!({ algorithm: 0 })
        seller
      end
      configuration['fullit']['sellers'] = seller_conf
      setting.update_columns(configuration: configuration)
    end
  end

  desc 'Add surveys to buyer notification setting'
  task add_surveys_configuration: :environment do
    Setting.where(service_id: 6).each do |setting|
      configuration = setting.configuration
      next if configuration.blank? || configuration['notification'].blank?

      csat_configuration = { 'csat' => { 'active' => false, 'cc' => false } }
      configuration['notification']['buyer']['mail']['surveys'] = csat_configuration
      setting.update_columns(configuration: configuration)
    end
  end

  desc 'Activate surveys to customer satisfaction notification setting'
  task activate_surveys_configuration: :environment do
    companies = ['BancoEstado - Delivery Tarjetas', 'REDGLOBAL', 'Copec',
                 'C/Moran', 'Club Social y Deportivo Colo-Colo', 'esderulos',
                 'Boss Babe Beauty', 'Buale', 'The Body Shop',
                 'Rotter & Krauss', 'Privilege', 'SHIVSAI SPA', 'DBS Chile',
                 'Okwu', 'Page One', 'kine-store',
                 'B2B WEB DISTRIBUICAO DO PRODUTOS CHILE SPA', 'MyCOCOS',
                 'Raindoor', 'Organik Cosmetics', 'SUMUP', 'Tua Retail',
                 'ALISHA PERFUMES', 'La Planchetta Chile SPA',
                 'Rulos chile spa', 'IVMEDICAL', 'Citrola', 'Novatex SPA',
                 'Club de Perros y Gatos', 'ORX FIT', 'Scorpi', 'Grylan',
                 'Lgnd Spa', 'HERBOLARIA DE CHILE S.A. BODEGA',
                 'gosh babe spa', 'KANKA', 'Prestige SpA', 'Musicland',
                 'Your Goal', 'BebeAComer', 'Barbizon', 'Oh My Skin SpA',
                 'BEESE', 'Amantani Tienda', 'Naay', 'sosmart sa',
                 'Trenzaduría Fraile', 'Chantilly', 'CafeStore', 'Uma Baby',
                 'Agencia Salmón SpA', 'Inspirada Hecho a Mano',
                 'RH-STORES SpA. (Village y Argos Party)', 'Cotillón Activarte',
                 'Revesderecho', 'ClearSkin Chile', 'Vaporizadores Chile',
                 'Mali Shop', 'Comercializadora Needle S.A.',
                 'Comercial Giovo Limitada', 'Espesales', 'VAL SUMINISTROS SPA',
                 'Trip Helmets', 'Casa del Cuenco', 'HILANDERIA MAISA S.A.',
                 'Simmedical', 'Winkler Nutrition', 'GNOMO', 'MioBioChile',
                 'Galeria Impresionarte', 'DEMARIE SPA', 'TPS',
                 'MG SOLUCIONES TI SPA', 'Papaya Bragas SPA',
                 'Lucky Diamonds SpA', 'Saint-malē', 'Casa Moda', 'Ortotek',
                 'Maikra SPA', 'MDL Store', 'DER EDICIONES', 'El Libero',
                 'Nostalgic', 'Outlet Médico', 'CG Cosmetics',
                 'Libreria Peniel', 'VESSI SpA', 'natural detox ', 'Mi Placard',
                 'Bazar Fungi', 'Mepsystem & ResinArt', 'INDAH STORE',
                 'Aritrans', 'Secretos de Amor', 'MiFoto', 'StreetMachine',
                 'EDITORIAL AMANUTA', 'Pethome', 'Automatizate ', 'Black Crown',
                 'Ortomolecular Chile', 'mamás mateas', 'crissaraos',
                 'Rosa Bergamota', 'Indigo de Papel',
                 'Peluquerías Integrales S.A.', 'Detogni', 'BY DELUXE']
    puts 'Init activate surveys to customer satisfaction notification setting'.green
    puts '======================================='.green
    counter = 0
    Setting.joins('LEFT JOIN entities entity ON entity.actable_id = company_id')
           .where(entity: { name: companies },
                  settings: { service_id: 6 }).each do |setting|
      configuration = setting.configuration
      next if configuration.blank? || configuration['notification'].blank?

      csat_configuration = { 'csat' => { 'active' => true, 'cc' => false } }
      configuration['notification']['buyer']['mail']['surveys'] = csat_configuration
      counter += 1
      puts "#{counter}. Company ID: #{setting.try(:company_id)} updated successfully".green
      setting.update_columns(configuration: configuration)
    end
    puts '======================================='.green
    puts 'Finished'.green
  end

  desc 'Send emergency rates to integrations'
  task send_emergency_rates_to_integrations: :environment do
    puts 'Init process'.green
    puts '======================================='.green

    Setting.by_service(2).find_each(batch_size: 50) do |setting|
      next unless setting.company.present?

      webhook = Setting.pp(setting.company_id).configuration['pp']['webhook']['package']
      unavailable_integrations = %w[dafiti opencart drupal magento magento_two api2cart bootic bsale jumpseller vtex]
      account = setting.company.current_account
      configuration = setting.configuration.dig('fullit', 'sellers')
      next if [account, configuration].any?(&:blank?)

      sellers = configuration.reject do |seller|
        unavailable_integrations.include?(seller.keys.first) ||
          seller[seller.keys.first]['client_id'].blank?
      end
      sellers.each do |seller|
        EmergencyRates::Sellers::Base.new({ seller: seller,
                                            setting: setting,
                                            account: account,
                                            webhook: webhook }).send_rate
      end
    end

    puts '======================================='.green
    puts 'Finished process'.green
  end
end
