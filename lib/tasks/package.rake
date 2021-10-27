namespace :package do
  desc 'Set packages tracking number'
  task set_tracking: :environment do
    Publisher.purge('core.get_tracking')
    filter_sql = "(is_payable is true AND courier_for_client IN ('starken') OR is_payable is false OR is_payable is NULL)"
    filter_sql += " AND destiny NOT IN ('Retiro Cliente', 'Despacho Retail')"
    filter_sql += " AND (tracking_number is NULL OR tracking_number LIKE '')"
    filter_sql += ' AND courier_for_client is NOT NULL'
    filter_sql += ' AND DATE(created_at) BETWEEN ? AND ?'
    from = (Time.zone.now - 12.hours).to_date
    to = Time.zone.now.to_date
    couriers_enabled = Courier.unscoped.where('tracking_generator LIKE ?', '%task%')
    courier_names = couriers_enabled.pluck(:name).map(&:downcase)
    Package.where([filter_sql, from, to])
           .where('LOWER(courier_for_client) IN (?)', courier_names)
           .map(&:set_tracking)
  end

  desc 'Set packages price'
  task set_price: :environment do
    Package.where("created_at::date BETWEEN ? AND ?", (Date.current - 4.days), Date.current)
           .where(courier_for_client: [nil, ''], without_courier: [false, nil])
           .each(&:set_price)
  end

  desc 'It set price by specific date or last day'
  task :confirm_price, [:year, :month, :day] => :environment do
    date =
      if args[:year].to_i.zero? && args[:month].to_i.zero? && args[:day].to_i.zero?
        Date.current - 1.days
      else
        Date.new(args[:year].to_i, args[:month].to_i, args[:day].to_i)
      end
    Package.complete_date(date.year, date.month, date.day, without_courier: false).each(&:set_price)
  end

  desc 'It sent to fulfillment a package with inventory_activity created'
  task :send_to_wms, [:id] => :environment do |t, args|
    puts '======================================='.yellow
    puts 'Init Task send_to_wms'.green

    package = Package.where(id: args[:id]).where.not(inventory_activity: nil)[0]
    return if package.blank?
    company = package.branch_office.company
    success = FulfillmentService.create_package({ packages: [package.serialize_data!] }, company.id)
    raise 'Tuvimos un problema corroborando el stock de los SKU’s solicitados. intente denuevo más tarde.' unless success

    puts 'End Task send_to_wms'.green
    puts '======================================='.yellow
  end

  desc 'Generate print by avery format.'
  task :print_avery, [:company_id] =>:environment do |task, args|
    data = Package.today_packages_with_exception.joins(branch_office: :company).where('companies.id = ?', args[:company_id])
    unless data.blank?
      link = Opit.generate_avery(data)
      puts link.to_s.green
    end
  end


  desc 'TEST Packages'
  task test_new_courier: :environment do
    r = Random.new
    packages = []
    (1..2000).each do |num|
      random_commune = Commune.find((r.rand(747) == 0 ? 308 : r.rand(747)))
      commune = random_commune.present? ? random_commune.id : 308
      # puts random_commune.name
      package = Package.new(full_name: 'TEST-hiro',
                            branch_office_id: 1,
                            email: 'hirochi@shipit.cl',
                            reference: "TEST-h-#{num}",
                            destiny: 'Domicilio',
                            approx_size: '',
                            packing: 'Sin empaque',
                            items_count: 1,
                            shipping_type: 'Normal',
                            is_payable: false,
                            cellphone: '74719945',
                            without_courier: false,
                            is_sandbox: false,
                            address_attributes: {
                              street: 'TEST-lugar',
                              number: r.rand(1000),
                              commune_id: commune,
                              complement: 'TEST-lugar'
                            },
                            width: 10,
                            height: 10,
                            length: 10,
                            weight: 1,
                            courier_branch_office_id: 0)
      @ship = Opit.new(package)
      cost = @ship.shipment_cost['shipment']
      price = @ship.shipment_price['shipment']
      if cost && price
        package.update_attributes(courier_for_entity: price['courier'],
                                  courier_for_client: cost['courier'],
                                  shipping_cost: cost['total'],
                                  shipping_price: price['total'],
                                  volume_ranking: price['interval'],
                                  delivery_time: price['delivery_time'],
                                  volume_price: price['pv'])
        packages << package
      else
        puts 'Fail'.red.swap
      end
    end
    file = CSV.generate(encoding: 'UTF-8'.encoding) do |csv|
      csv << ['Servicio', 'Cliente', 'Destinatario', 'Comuna', 'Length', 'Width', 'Height', 'Weight', 'Por pagar', 'Sucursal', 'Empaque',
              'Courier Seleccionado Cliente', 'Courier Shipit', 'Precio envío', 'Material extra', 'Precio total', 'Código envío', 'Items',
              'Fecha', 'Es Fragil', 'Papel regalo', 'Tiempo envío', 'Courier', 'Número de seguimiento', 'Volumen',
              'Peso Equivalente', 'Margen', 'Devolución', 'Costo Shipit', 'Código Shipit']
      packages.each do |package|
        csv << [package.service, package.branch_office.company.try(:name), package.full_name, package.address.commune.try(:name), package.length, package.width,
                package.height, package.weight, package.is_payable, package.destiny, package.packing, (package.courier_selected ? 'Si' : 'No'),
                package.courier_for_client, package.shipping_price.try(:to_i), package.material_extra.try(:to_i), package.total_price.try(:to_i),
                package.reference, package.items_count, I18n.l(package.created_at, format: :datetimepicker),
                package.is_fragile, package.is_wrapper_paper, package.shipping_type, package.courier_for_entity,
                package.tracking_number, package.volume, package.volume_price, package.profit, package.is_returned,
                package.shipping_cost.try(:to_i), package.shipit_code]
      end
    end
    OrderMailer.test_new_courier(file).deliver
  end

  desc 'integrations metrics'
  task integrations_metrics: :environment do
    cos = Company.all.select { |c| c.any_integrations? }
    total_dafiti = 0
    total_prestashop = 0
    total_woocommerce = 0
    total_shopify = 0
    total_bootic = 0
    cos.map do |c|
      integrations = c.integrations_activated
      packages = c.packages.where.not(mongo_order_id: nil)
      dafiti = packages.select { |w| w.mongo_order_seller == 'dafiti' }.try(:size)
      prestashop = packages.select { |w| w.mongo_order_seller == 'prestashop' }.try(:size)
      woocommerce = packages.select { |w| w.mongo_order_seller == 'woocommerce' }.try(:size)
      shopify = packages.select { |w| w.mongo_order_seller == 'shopify' }.try(:size)
      bootic = packages.select { |w| w.mongo_order_seller == 'bootic' }.try(:size)
      total_dafiti += dafiti || 0
      total_prestashop += prestashop || 0
      total_woocommerce += woocommerce || 0
      total_shopify += shopify || 0
      total_bootic += bootic || 0
      months = ( Date.current - Date.parse(c.created_at.to_s) ).to_s.split('/').first.to_f / 30
      puts "Compañia: #{c.name}, dafiti: #{dafiti}, prestashop: #{prestashop}, woocommerce: #{woocommerce}, shopify: #{shopify}, bootic: #{bootic}"
    end
    puts "dafiti: #{total_dafiti}, prestashop: #{total_prestashop}, woocommerce: #{total_woocommerce}, shopify: #{total_shopify}, bootic: #{total_bootic}"
  end

  desc 'cleaning scheduled set queue'
  task clear_scheduled_set_queue: :environment do
    puts "clear ScheduledSet queue at: #{Time.current.to_s}"
    require 'sidekiq/api'
    Sidekiq::ScheduledSet.new.clear
  end

  desc 'set_price'
  task set_price_for: :environment do
    to_set_price_ids = JSON.parse(File.read("#{Rails.root}/lib/data/set_price.json"))
    pas = Package.where(id: to_set_price_ids['ids'], without_courier: false)
    total_ids = to_set_price_ids['ids'].count
    total_found_packages = pas.count
    puts "found: #{total_found_packages} of #{total_ids}"
    pas.each_with_index do |p, i|
      p.set_price
      puts "(#{i}/#{total_found_packages}): setting price for #{p.id}"
    end
  end


  desc 'do monoi packages'
  task :monoi_packages, [:real] => :environment do |t, args|
    to_rebuild = JSON.parse(File.read("#{Rails.root}/lib/data/monoi_packages_2.csv"))
    data = to_rebuild['asd']
    progress = 1
    nil_skus = ''
    grouped = data.group_by { |w| w['ref'] }
    total = grouped.keys.count
    skus = FulfillmentService.by_client(16)

    result = grouped.map do |group_ref, group_skus|
      puts "#{progress} / #{total}"
      package = Package.find_by(reference: group_ref, branch_office_id: 16)
      progress += 1
      if package.blank?
        "#{group_ref} failed, package_not_found"
      else
        inv_act_ord_attr = group_skus.map do |sku_detail|
          next if sku_detail['name'].include?('PACKP')
          sku = skus.find{|sk| sk['name'] == sku_detail['name']}
          if sku.blank?
            nil_skus += "#{sku_detail['name']} "
          end
          { "sku_id" => sku ? sku['id'] : nil, "amount" => sku_detail['qty'], "warehouse_id" => sku ? sku['warehouse_id'] : nil }
        end
        if inv_act_ord_attr.blank? || inv_act_ord_attr.to_s.include?('"sku_id"=>nil')
          "#{group_ref} failed bad_structure"
        else
          base = {"inventory_activity_orders_attributes" => inv_act_ord_attr}
          puts base.to_s
           if args[:real].to_s == 'true'
            package.update_columns(inventory_activity: base)
            package.retry_fulfillment
          end
        end
      end
    end

    failed = result.select{ |w| w.to_s.include?('failed') }
    not_found = failed.select{|w| w.to_s.include?('not_found')}
    bad = failed.select{|w| w.to_s.include?('structure')}

    puts "total: #{data.count}"
    puts "fallidos: #{failed.count}"
    puts "pedidos no encontrados: #{not_found.count} \n #{not_found.map(&:to_i).join(' , ')}"
    puts "pedidos mal formateados: #{bad.count} \n #{bad.map(&:to_i).join(' , ')}"
    puts "#{nil_skus}"
  end

  desc 'Manually setting up new order service fields'
  task order_service_new_fields: :environment do
    length = 0
    OrderService.all.offset(105000).each_slice(50) do |batch|
      length = length + batch.size
      puts "HERE BATCH #{length}"
      batch.each do |w|
        puts w.id
        w.set_base_info
      end
    end
  end

  desc 'Print all labels from bubba bags'
  task printer_bubba: :environment do
    company = Company.find(1148)
    available = Setting.printers(1148).printer_available
    branch_offices = company.branch_offices.ids

    logs = []

    CSV.foreach("#{Rails.root}/lib/data/labels.csv", headers: true) do |row|
      data = row.to_h.with_indifferent_access
      package = Package.find_by(reference: data[:id])
      next unless package.present?
      PrinterJob.perform_now([package], available['id_printer'])
      logs << "PRINTER PACKAGE: #{package.id} - #{package.reference}".green.swap
    end
    logs.each { |l| puts l }
  end

  desc 'Calculate all packages accomplishment'
  task calculate_accomplishment: :environment do
    puts 'Init set accomplishment to all packages'.green
    progress = 1.0
    company_count = Company.count
    Company.all.each do |company|
      puts "#{progress / company_count * 100} %".red
      progress += 1
      packages = company.packages.left_outer_joins(:check).accomplishment_select
      next if packages.size.zero?

      packages.group_by { |p| p.created_at.strftime('%m/%Y') }.each do |date, data|
        puts "COMPANY: #{company.name} - DATE: #{date}".cyan.swap
        AccomplishmentService.new(packages: data, company: company).process
      end
    end
  end

  desc 'Calculate delivered packages accomplishment'
  task package_accomplishment: :environment do
    puts 'Init set accomplishment to all packages'.green
    puts '======================================='.yellow
    progress = 1.0
    company_count = Company.count
    Company.all.each do |company|
      puts "#{progress / company_count * 100} %".red
      progress += 1
      packages = company.packages
                        .where(created_at: (Date.current.beginning_of_day - 15.day)..(Date.current.end_of_day))
                        .left_outer_joins(:check)
                        .accomplishment_select
      next if packages.size.zero?

      AccomplishmentService.new(packages: packages, company: company).process
    end
  end

  desc 'Package product migration'
  task sku_migration: :environment do
    Package.from_ff.by_date(12).where(platform: :suite).each do |package|
      next if package.inventory_activity['inventory_activity_orders_attributes'].size.zero?

      package.inventory_activity['inventory_activity_orders_attributes'].map do |sku|
        next unless sku['id'].present?

        sku['sku_id'] = sku['id']
        sku.delete_if { |k, _v| k == 'id' }
        sku
      end
      package.update_columns(inventory_activity: package.inventory_activity)
    end
  end

  desc 'Migrate all shipments billing_date'
  task migrate_billing_date: :environment do
    Package.find_each(batch_size: 10_000).each do |package|
      package.update_columns(billing_date: package.created_at)
    end
  end

  desc 'Get shipments delayed per day'
  task shipments_delayed: :environment do
    return if Date.current.holiday?

    sub_statuses_applied = %w[received_for_courier in_route in_transit]
    couriers_applied = %w[bluexpress chilexpress starken muvsmart motopartner]
    headers = %w[tracking_number embalaje motivo]
    xlsxs = CourierService.base_hash_delayed_packages
    packages = Package.where(created_at: (45.days.ago)..Date.current,
                             courier_for_client: couriers_applied,
                             sub_status: sub_statuses_applied)
    management_step = ManagementStep.find_by(name: 'status_asked')
    quantity_to_process = packages.size
    progress = 0
    packages.each do |package|
      begin
        progress += 1
        puts "Procesando: #{package.id}. #{progress}/#{quantity_to_process}"
        delayed = package.delayed?
        next unless delayed
        next unless package.shipping_managements.size.zero?

        puts 'Pedido Atrasado'
        shipping_management = package.shipping_managements.create(kind: 0, status: 0)
        shipping_management.management_processes.create(management_step_id: management_step.id)
        packing = package.package_packing ? package.package_packing.packing.description : ''
        xlsxs["#{package.courier_for_client}_xlsx".to_sym][:spread_values] << [package.tracking_number, packing, delayed[:motive]]
      rescue StandardError => e
        puts "ha ocurrido un problema (#{e.message}) con el package #{package.id}"
      end
    end
    xlsxs.each do |courier, detail_data|
      next if detail_data[:spread_values].size.zero?

      xlsx = SpreadsheetArchitect.to_xlsx(headers: headers, data: detail_data[:spread_values])
      File.open("#{Rails.root}/public/xlsx/#{courier}.xlsx", 'w+b') do |f|
        f.write(xlsx)
        client = ::Aws::S3::Resource.new
        bucket = client.bucket('packages-xls-shipit')
        dir = bucket.object("proactive-monitoring-xlsx/#{Time.current.year}/#{Time.current.month}/#{Time.current.day}/#{courier}.xlsx")
        dir.put(body: xlsx, content_type: 'application/xlsx', acl: 'public-read')
        subject = "#{detail_data[:subject]} (#{detail_data[:spread_values].size}) atrasados, #{courier}, #{Date.current.strftime('%Y/%m/%d')}"
        Publisher.publish('proactive_monitoring', { courier: courier,
                                                    xlsx_url: dir.public_url,
                                                    cc: detail_data[:cc],
                                                    to: detail_data[:email_to],
                                                    quantity: detail_data[:spread_values].size,
                                                    cheer: detail_data[:cheer],
                                                    subject: subject })
      end
    end
  end

  desc 'Send pickup same_day alert'
  task send_sdd_pickup_alert: :environment do
    Rails.logger.info { '🚴 Sending SDD pickup alert'.yellow }

    selected_packages =
      Package.where(
        'created_at BETWEEN ? AND ? AND LOWER(courier_for_client) IN (?)',
        Time.zone.now.beginning_of_day, Time.zone.now,
        Courier.available_with_same_day_delivery.pluck(:symbol)
      ).group_by(&:branch_office_id)

    days = Package.calculate_days(datetime: DateTime.current - 10.minutes).days
    sdd_date = I18n.l(Date.current + days, format: :day_date_month).titleize
    selected_packages.each do |branch_office_id, grouped_packages|
      branch_office = BranchOffice.find_by(id: branch_office_id)
      company = branch_office&.company
      next if company.blank?

      entity = company.entity
      email_contact = entity.email_contact
      email_notification = entity.email_notification
      bcc = ['notificacionesretiros@shipit.cl']
      bcc.push(email_contact.split(',')) if email_contact.present?
      bcc.push(email_notification.split(',')) if email_notification.present?
      bcc += company.contacts.where(role_name: 'operative').pluck(:email)

      date_to_pick = days.zero? ? I18n.t('ssd.zero') : " #{sdd_date}"

      pickup_alert_data = {
        shipments: grouped_packages,
        account: company.current_account,
        specific_name: entity.specific.name,
        hero: branch_office.hero.serialize_data!,
        bcc: bcc,
        date_to_pick: date_to_pick,
        same_day_delivery: true
      }
      Publisher.publish('shipment_notifications', pickup_alert_data)
    end
  end

  desc 'Send pickup heroes alert'
  task send_heroes_pickup_alert: :environment do
    Rails.logger.info { '🦸 Sending heroes pickup alert'.yellow }

    selected_packages =
      Package.where(
        'created_at BETWEEN ? AND ? AND NOT LOWER(courier_for_client) IN (?)',
        Time.zone.now.beginning_of_day,
        Time.zone.now,
        Courier.available_with_same_day_delivery.pluck(:symbol)
      )
    Rails.logger.info { "📦 #{selected_packages.size} packages were found".yellow }

    packages_by_branch_offices = selected_packages.group_by(&:branch_office_id)
    date = Date.current + Package.calculate_days(
      datetime: DateTime.current - 10.minutes
    ).days
    date_to_pick = I18n.l(date, format: :day_date_month).titleize
    packages_by_branch_offices.each do |branch_office_id, grouped_packages|
      branch_office = BranchOffice.find_by(id: branch_office_id)
      company = branch_office&.company
      next if company.blank?

      allow_pickup = Setting
                     .notification(company.id)
                     .configuration['notification']['client']['pickup']
      next unless allow_pickup

      entity = company.entity
      email_contact = entity.email_contact
      email_notification = entity.email_notification
      bcc = ['notificacionesretiros@shipit.cl']
      bcc.push(email_contact.split(',')) if email_contact.present?
      bcc.push(email_notification.split(',')) if email_notification.present?
      bcc += company.contacts.where(role_name: 'operative').pluck(:email)

      pickup_alert_data = {
        shipments: grouped_packages,
        account: company.current_account,
        specific_name: entity.specific.name,
        hero: branch_office.hero.serialize_data!,
        bcc: bcc,
        date_to_pick: date_to_pick,
        same_day_delivery: false
      }
      Publisher.publish('shipment_notifications', pickup_alert_data)

    end

    Rails.logger.info { '✅ Finished!'.green }
  end
end

