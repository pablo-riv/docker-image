namespace :backoffice_couriers do
  desc 'Generate Base Data for new Implementation'
  task generate_base_data_from_csv: :environment do
    Rake::Task['backoffice_couriers:generate_transport_types'].invoke
    Rake::Task['backoffice_couriers:generate_delivery_types'].invoke
    Rake::Task['backoffice_couriers:generate_payment_types'].invoke
    Rake::Task['backoffice_couriers:update_base_courier_communes_translations'].invoke
    Rake::Task['backoffice_couriers:update_couriers_coverages'].invoke
  end

  desc 'Generate Base Generic Transport Types Data'
  task generate_transport_types: :environment do
    puts '=== Iniciando Actualización ==='.green.swap
    csv = CSV.read('lib/data/backoffice_base_data.csv', headers: true)
    puts '=== Iniciando Migración de Tipos de Transporte ==='.green.swap
    errors_transport_types = []
    transport_types = csv.values_at('Tipo de transporte').uniq.flatten.compact.map(&:titleize)
    already_created = TransportType.where('LOWER(name) IN (?)', transport_types.map(&:downcase))

    if already_created.count == transport_types.count
      puts 'Todos los Tipos de Transporte encontrados ya existen en la Base de Datos'.blue.swap
    else
      transport_types.each do |transport_type|
        begin
          TransportType.find_or_create_by(name: transport_type)
        rescue StandardError => e
          errors_transport_types << "Transporte #{transport_type} con error: #{e.message}"
        end
      end
    end
    errors_transport_types.each { |e| puts e.yellow } if errors_transport_types.present?
    puts "Migración finalizada para Tipos de Transporte con un total de #{errors_transport_types.size} errores".yellow.swap if errors_transport_types.present?
    puts 'Migración finalizada para Tipos de Transporte sin errores'.green.swap unless errors_transport_types.present?
  end

  desc 'Generate Base Generic Delivery Types Data'
  task generate_delivery_types: :environment do
    puts '=== Iniciando Actualización ==='.green.swap
    csv = CSV.read('lib/data/backoffice_base_data.csv', headers: true)
    puts '=== Iniciando Migración de Tipos de Envío ==='.green.swap
    errors_delivery_types = []
    delivery_types = csv.values_at('Lugar de entrega').uniq.flatten.compact.map(&:titleize)
    already_created = DeliveryType.where('LOWER(name) IN (?)', delivery_types.map(&:downcase))
    if already_created.count == delivery_types.count
      puts 'Todos los Tipos de Envío encontrados ya existen en la Base de Datos'.blue.swap
    else
      delivery_types.each do |delivery_type|
        begin
          DeliveryType.find_or_create_by(name: delivery_type)
        rescue StandardError => e
          errors_delivery_types << "Envío #{delivery_type} con error: #{e.message}"
        end
      end
    end
    errors_delivery_types.each { |e| puts e.yellow } if errors_delivery_types.present?
    puts "Migración finalizada para Tipos de Envío con un total de #{errors_delivery_types.size} errores".yellow.swap if errors_delivery_types.present?
    puts 'Migración finalizada para Tipos de Envío sin errores'.green.swap unless errors_delivery_types.present?
  end

  desc 'Generate Base Generic Payment Types Data'
  task generate_payment_types: :environment do
    puts '=== Iniciando Actualización ==='.green.swap
    csv = CSV.read('lib/data/backoffice_base_data.csv', headers: true)
    puts '=== Iniciando Migración de Tipos de Pago ==='.green.swap
    errors_payment_types = []
    payment_types = csv.values_at('Tipo de pago').uniq.flatten.compact.map(&:titleize)
    already_created = PaymentType.where('LOWER(name) IN (?)', payment_types.map(&:downcase))
    if already_created.count == payment_types.count
      puts 'Todos los Tipos de Pago encontrados ya existen en la Base de Datos'.blue.swap
    else
      payment_types.each do |payment_type|
        begin
          PaymentType.find_or_create_by(name: payment_type)
        rescue StandardError => e
          errors_payment_types << "Pago #{payment_type} con error: #{e.message}"
        end
      end
    end
    errors_payment_types.each { |e| puts e.yellow } if errors_payment_types.present?
    puts "Migración finalizada para Tipos de Pago con un total de #{errors_payment_types.size} errores".yellow.swap if errors_payment_types.present?
    puts 'Migración finalizada para Tipos de Pago sin errores'.green.swap unless errors_payment_types.present?
  end

  desc 'Update Base Courier Communes Translations Data'
  task update_base_courier_communes_translations: :environment do
    puts '=== Iniciando Actualización ==='.green.swap
    csv = CSV.read('lib/data/backoffice_communes_translations.csv', headers: true)
    puts '=== Iniciando Migración de Traducción de Comunas ==='.green.swap
    errors_courier_commune_translations = []
    csv.each do |row|
      begin
        commune = Commune.find_by(id: row['commune.id'])
        courier = Courier.find_by('LOWER(name) = ?', row['courier'].try(:downcase))
        unless [commune, courier].all?(&:present?)
          puts "No se cumplen las condiciones para generar traducción:\nCOURIER: #{courier.try(:name) || 'N/A'}\nCOMUNA: #{commune.try(:name) || 'N/A'}".red
          next errors_courier_commune_translations << "#{row['courier']} - #{row['commune.id']} - #{row['commune.name']}"

        end

        courier.translate_communes_couriers.find_or_create_by(name: row['traduccion'], commune_id: commune.id)
      rescue StandardError => _e
        errors_courier_commune_translations << "#{row['courier']} - #{row['commune.id']} - #{row['commune.name']}"
      end
    end
    errors_courier_commune_translations.each { |e| puts e.yellow } if errors_courier_commune_translations.present?
    puts "Migración finalizada para Traducción de Comunas con un total de #{errors_courier_commune_translations.size} errores".yellow.swap if errors_courier_commune_translations.present?
    puts 'Migración finalizada para Traducción de Comunas sin errores'.green.swap unless errors_courier_commune_translations.present?
  end

  desc 'Update Base Courier Coverages Data'
  task update_couriers_coverages: :environment do
    row_errors = []
    not_created = { transport_types: [], delivery_types: [], payment_types: [], communes: [], couriers: [] }
    counter = 0
    puts '=== Iniciando Actualización ==='.green.swap
    csv = CSV.read('lib/data/backoffice_base_data.csv', headers: true)
    total_rows = csv.count
    csv.each do |row|
      begin
        courier_name = row['Courier'].downcase
        courier_name = 'Muvsmart' if courier_name == '99minutos'
        courier = Courier.find_by('LOWER(name) = (?) AND country_id = (?)', courier_name.try(:downcase), 1)
        unless courier.present?
          counter += 1
          puts "== Progreso: #{counter}/#{total_rows}".yellow
          not_created[:couriers] << row['Courier']
          next row_errors << counter + 1
        end

        courier_origin_commune = Commune.find_by('LOWER(name) = ?', row['Origen'].try(:downcase))
        courier_origin_commune = courier.translate_communes_couriers.find_by('LOWER(name) = ?', row['Origen'].try(:downcase)).try(:commune) unless courier_origin_commune.present?

        not_created[:communes] << row['Origen'] unless courier_origin_commune.present?

        courier_origin = courier.courier_origins.find_or_create_by(commune_id: courier_origin_commune.id)
        courier_destiny_commune = Commune.find_by('LOWER(name) = ?', row['Destino'].try(:downcase))
        not_created[:communes] << row['Destino'] unless courier_destiny_commune.present?

        courier_destiny = courier.courier_destinies.find_or_create_by(commune_id: courier_destiny_commune.id)
        courier_service_type = courier.courier_service_types.find_by('LOWER(name) = ?', row['Tipo de servicio'].try(:downcase))
        courier_service_type = courier.courier_service_types.create(name: row['Tipo de servicio'], description: row['Tipo de servicio']) unless courier_service_type.present?

        transport_type = TransportType.find_by('LOWER(name) = ?', row['Tipo de transporte'].try(:downcase))
        not_created[:transport_types] << row['Tipo de transporte'] unless transport_type.present?

        courier_transport_type = courier.courier_transport_types.find_or_create_by(transport_type_id: transport_type.id)

        delivery_type = DeliveryType.find_by('LOWER(name) = ?', row['Lugar de entrega'].try(:downcase))
        not_created[:delivery_types] << row['Lugar de entrega'] unless delivery_type.present?

        courier_delivery_type = courier.courier_delivery_types.find_or_create_by(delivery_type_id: delivery_type.id)

        payment_type = PaymentType.find_by('LOWER(name) = ?', row['Tipo de pago'].try(:downcase))
        not_created[:payment_types] << row['Tipo de pago'] unless payment_type.present?

        courier_payment_type = courier.courier_payment_types.find_or_create_by(payment_type_id: payment_type.id)

        estimated_delivery_days = row['Plazo estimado'].presence || 2000
        all_data_required_ready =
          [courier_origin_commune,
           courier_destiny_commune,
           courier_service_type,
           courier_transport_type,
           courier_delivery_type,
           courier_payment_type,
           estimated_delivery_days].all?(&:present?)

        unless all_data_required_ready
          puts 'Falló creación de cobertura por datos faltantes'.red
          counter += 1
          puts "== Progreso: #{counter}/#{total_rows}".yellow
          next row_errors << counter + 1
        end
        courier_coverage_params = { estimated_delivery_days: estimated_delivery_days.to_i,
                                    courier_origin_id: courier_origin.id,
                                    courier_destiny_id: courier_destiny.id,
                                    courier_service_type_id: courier_service_type.id,
                                    courier_payment_type_id: courier_payment_type.id,
                                    courier_transport_type_id: courier_transport_type.id,
                                    courier_delivery_type_id: courier_delivery_type.id }
        courier_coverage = CourierCoverage.unscoped.find_by(courier_coverage_params.except(:estimated_delivery_days))
        CourierCoverage.find_or_create_by(courier_coverage_params) unless courier_coverage.present?

        counter += 1
        puts "== Progreso: #{counter}/#{total_rows}".yellow
      rescue StandardError => _e
        counter += 1
        row_errors << counter + 1
        puts "== Progreso: #{counter}/#{total_rows}".yellow
      end
    end
    row_errors_output = ["Filas con error: #{row_errors.join(',')}"]
    not_created_output = not_created.map { |model, list| "#{model.to_s.titleize}: #{list.uniq}" }
    File.write('lib/data/backoffice_base_data_errors.txt', (row_errors_output + not_created_output).join("\n"))
    puts "Actualización finalizada con un total de #{row_errors.size} errores".yellow.swap if row_errors.present?
    puts 'Actualización finalizada sin errores'.green.swap unless row_errors.present?
  end

  desc 'Create CourierDestinies and CourierOrigins from prices or costs spreadsheet'
  task :populate_from_spreadsheet, [:country_id] => :environment do |_t, args|
    errors = []
    puts '=== Iniciando Carga ==='.green.swap
    csv = CSV.read('lib/data/backoffice_courier_spreadsheet.csv', headers: true)
    country_id = args[:country_id].presence || Country.find_by(name: 'Chile').try(:id) || 1
    csv.each do |row|
      begin
        courier = Courier.find_by('LOWER(name) = LOWER(?) AND country_id = (?)', row['Courier'], country_id)
        unless courier.present?
          puts "No se pudo encontrar courier con nombre: '#{row['Courier']}' y country_id: '#{country_id}'".red
          errors << { courier: row['Courier'] }
          next
        end

        commune_origin = Commune.joins(:region).find_by(name: row['Origen'].try(:upcase), regions: { country_id: country_id })
        unless commune_origin.present?
          puts "No se pudo encontrar comuna de origen con nombre: '#{row['Origen']}' y country_id: '#{country_id}'".red
          errors << { commune_origin: row['Origen'] }
          next
        end

        courier_origin = CourierOrigin.find_or_create_by(courier_id: courier.id, commune_id: commune_origin.id)
        errors << { courier_origin: row['Origen'] } unless courier_origin.present?

        puts "Origen para #{row['Origen']} y courier #{courier.name} registrado".green
        commune_destiny = Commune.joins(:region).find_by(name: row['Destino'].try(:upcase), regions: { country_id: country_id })
        unless commune_destiny.present?
          puts "No se pudo encontrar comuna de destino con nombre: '#{row['Destino']}' y country_id: '#{country_id}'".red
          errors << { commune_destiny: row['Destino'] }
          next
        end
        courier_destiny = CourierDestiny.find_or_create_by(courier_id: courier.id, commune_id: commune_destiny.id)
        errors << { courier_destiny: row['Destino'] } unless courier_destiny.present?

        puts "Destino para #{row['Destino']} y courier #{courier.name} registrado".green
      rescue StandardError => e
        puts "ERROR: #{e.message}".red.swap
      end
    end
    File.write('lib/data/backoffice_courier_spreadsheet_errors.txt', errors.join("\n")) if errors.present?
    puts "Registro finalizado con un total de #{errors.size} errores".yellow.swap if errors.present?
    puts 'Registro finalizado sin errores'.green.swap unless errors.present?
  end
end
