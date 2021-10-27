namespace :proactive_monitoring do
  desc 'seed data for proactive monitoring table'
  task seed: :environment do
    data = {
      Starken:
      { emails: %w[gabriela.marchant@starken.cl],
        main_email: 'shipit@starken.cl',
        greeting: 'Estimadas',
        shipping_reference: 'Carga/s',
        courier_id: Courier.find_by(symbol: 'starken').id,
        kind: 0 },
      Chilexpress:
      { emails: %w[hlagos@chilexpress.cl kbarriga@chilexpress.cl],
        main_email: 'ttoro@ext.chilexpress.cl',
        greeting: 'Estimada Tamar',
        shipping_reference: 'Encomienda/s',
        courier_id: Courier.find_by(symbol: 'chilexpress').id,
        kind: 0 },
      Bluexpress:
      { emails: %w[paola.lopez@bx.cl],
        main_email: 'karen.rebolledo@bx.cl',
        greeting: 'Estimada Karen',
        shipping_reference: 'Pedido/s',
        courier_id: Courier.find_by(symbol: 'bluexpress').id,
        kind: 0 }
    }
    CourierOperationalInformation.delete_all
    data.each { |_, value| CourierOperationalInformation.create(value) }
  end

  desc ''
  task load_current_shipping_management: :environment do
    puts '=== Iniciando Carga ==='.green.swap
    csv = CSV.read('lib/data/current_sp.csv', headers: true)
    counter = 0
    total_rows = csv.count
    csv.each do |row|
      begin
        counter += 1
        puts "== Progreso: #{counter}/#{total_rows}".yellow
        management_step = ManagementStep.find_by(name: row['management_status'])
        package = Package.find_by(id: row['package'])
        puts "package #{row['package']} no encontrado" unless package.present?
        next unless package.present?
        next if package.shipping_managements.present?

        shipping_management = package.shipping_managements.create(kind: 0,
                                                                  status: 0)
        shipping_management.management_processes
                           .create(management_step_id: management_step.id)
      rescue StandardError => e
        puts "Error #{e.message}/nBUGTRACE: #{e.backtrace}"
      end
    end
  end

  task add_zendesk: :environment do
    CourierOperationalInformation.where(zendesk_id: nil).each do |data|
      begin
        response = Zendesk::Api.new.search(data.main_email)
        raise if response.blank?

        zendesk_id = response['users'][0]['id']
        raise unless zendesk_id.present?

        raise unless data.update(zendesk_id: zendesk_id)

        puts "Courier Email: #{data.main_email} Zendesk ID: #{zendesk_id}".green
      rescue StandardError => e
        puts "No se asignó Zendesk ID #{zendesk_id} a #{data.main_email}".red
        puts "ID:#{data.id} Error #{e.message}\nBUGTRACE: #{e.backtrace}".red
        next
      end
    end
  end
end
