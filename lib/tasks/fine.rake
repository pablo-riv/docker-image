namespace :fine do
  desc 'Migrate fines discounts to refunds'
  task migrate_discounts_to_refunds: :environment do
    errors = []
    puts '=== Iniciando Migración ==='.green.swap
    Company.find_each(batch_size: 5).each do |company|
      puts "Migrando reembolsos de Compañía ID: #{company.id} | Nombre: #{company.name}".cyan.swap
      discounts = company.fines.refunds.joins('INNER JOIN packages on packages.id = fines.package_id')
      next puts 'Compañía sin Reembolsos'.yellow unless discounts.present?

      puts "Encontrados #{discounts.size} reembolsos por migrar".yellow
      discounts.each do |discount|
        begin
          refund_params = {
            date: discount.date,
            package_id: discount.package_id,
            invoice_number: '', # By default
            active: !discount.archive,
            comments: discount.comment,
            status: discount.resolved ? :approved : :rejected,
            motive: Refund::DISCOUNT_REASONS[discount.cause],
            responsible: Refund::DISCOUNT_RESPONSIBLES[discount.responsible],
            content_price: 0,
            overcharge_price: 0,
            shipping_price: discount.amount.to_i, # By default
            total_refund: discount.amount.to_i,
            assignee_type: :staff, # By default
            assignee_id: 1 # By default
          }
          new_refund = Refund.new(refund_params)
          new_refund.save!
        rescue StandardError => e
          errors << { id: discount.id, package_id: discount.package_id, company_id: company.id, message: e.message }
        end
      end
    end
    errors.each { |e| puts "Company ID: #{e[:company_id]}\nFine ID: #{e[:id]}\nPackage ID: #{e[:package_id]}\nError: #{e[:message]}\n --".yellow } if errors.present?
    puts "Migración finalizada con un total de #{errors.size} errores".yellow.swap if errors.present?
    puts 'Migración finalizada sin errores'.green.swap unless errors.present?
  end

  task update_refunds_data: :environment do
    errors = []
    counter = 0
    puts '=== Iniciando Migración ==='.green.swap
    csv = CSV.read('lib/data/refunds_enero_2021.csv', headers: true)
    total_rows = csv.count
    csv.each do |row|
      begin
        refund = Refund.find_by(id: row['id'].to_i)
        unless refund.present?
          counter += 1
          puts "== Progreso: #{counter}/#{total_rows}".yellow
          next errors << row['id']
        end

        refund.update_columns(content_price: row['content_price'].to_i,
                              shipping_price: row['shipping_price'].to_i,
                              total_refund: row['total_refund'].to_i)
        counter += 1
        puts "== Progreso: #{counter}/#{total_rows}".yellow
      rescue _e
        errors << row['id']
      end
    end
    puts "IDs con errores: [#{errors.join(', ')}]".red if errors.present?
    puts "Actualización finalizada con un total de #{errors.size} errores".yellow.swap if errors.present?
    puts 'Actualización finalizada sin errores'.green.swap unless errors.present?
  end
end
