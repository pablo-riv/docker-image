namespace :duemint do
  desc 'Connect with duemint'
  task migrate: :environment do
    duemint = DuemintService.new
    data = []
    duemint_data = duemint.clients(page: 1)
    total_pages = duemint_data[:records][:pages]
    data += duemint_data[:items]
    data += 2.upto(total_pages).map { |page| duemint.clients(page: (page.zero? ? 1 : page)).dig(:items) }.flatten
    runs = data.pluck('taxId').map { |run| run.gsub('.', '').gsub('-', '') }
    Entity.where("LOWER(actable_type) = 'company'").each do |entity|
      company = entity.specific
      next unless company.present?
      next unless entity.run.present?
      next unless runs.include?(entity.run.gsub('.', '').gsub('-', ''))

      client = data.find { |duemint_client| duemint_client['taxId'].gsub('.', '').gsub('-', '').try(:downcase) == company.run.gsub('.', '').gsub('-', '').try(:downcase) }
      next unless client.present?

      puts "COMPANY: #{company.name}, ID: #{company.id}".cyan.swap
      company.update_columns(duemint_id: client[:id], duemint_url: client[:url])
    end
  end

  desc 'Download documents'
  task migrate_invoices: :environment do
    duemint = DuemintService.new
    companies = Company.where.not(duemint_id: nil, duemint_url: nil)
    duemint.download(companies)
  end

  desc 'Update documents'
  task update: :environment do
    duemint = DuemintService.new
    Invoice.where.not(state: [3, 4], company_id: 1).find_each(batch_size: 10).each do |invoice|
      puts "ACTUALIZANDO INVOICE ID:#{invoice.duemint_reference} PARA LA COMPAÑÍA: #{invoice.company.name}".yellow.swap
      duemint_data = duemint.document_by_client(duemint_reference: invoice.duemint_reference)
      document_status = duemint.document_state(duemint_data['status'])
      next puts 'INVOICE NO PRESENTA CAMBIOS' if document_status == invoice.state.to_sym

      invoice.update(state: document_status)
      puts "INVOICE ID:#{invoice.duemint_reference} CON NUEVO ESTADO: #{invoice.state}".green.swap
    end
  end

  desc 'Update historic documents'
  task update_historic_documents: :environment do
    errors = []
    not_changes_needed = []
    counter = 0
    puts '=== Iniciando Actualización ==='.green.swap
    duemint = DuemintService.new
    csv = CSV.read('lib/data/duemint_by_reference_and_month.csv', headers: true)
    total_rows = csv.count
    csv.each do |row|
      begin
        invoice = Invoice.find_by(company_id: row['company_id'].to_i, emit_date: Date.new(row['billing_year'].to_i, row['billing_month'].to_i))
        unless invoice.present?
          counter += 1
          puts "== Progreso: #{counter}/#{total_rows}".yellow
          next errors << row['duemint_reference']
        end

        if invoice.duemint_reference == row['duemint_reference']
          counter += 1
          puts "== Progreso: #{counter}/#{total_rows}".yellow
          next not_changes_needed << row['duemint_reference']
        end

        puts "ACTUALIZANDO INVOICE ID:#{invoice.duemint_reference} PARA COMPAÑÍA: #{invoice.company.name}".yellow.swap
        duemint_data = duemint.document_by_client(duemint_reference: row['duemint_reference'])
        invoice.update(duemint_reference: duemint_data['id'],
                       paid_amount: duemint_data['paidAmount'],
                       paid_date: duemint_data['paidDate'],
                       taxes: duemint_data['taxes'],
                       net: duemint_data['net'],
                       notes: duemint_data['notes'],
                       gloss: duemint_data['gloss'],
                       due_date: duemint_data['dueDate'],
                       number: duemint_data['number'],
                       state: duemint.document_state(duemint_data['status']),
                       files: { pdf: duemint_data['pdf'],
                                xml: duemint_data['xml'],
                                url: duemint_data['url'] })
        counter += 1
        puts "== Progreso: #{counter}/#{total_rows}".yellow
      rescue _e
        errors << row['duemint_reference']
      end
    end
    puts "IDs con errores: [#{errors.join(', ')}]".red if errors.present?
    puts "Facturas sin modificación requerida: #{not_changes_needed.size}/#{total_rows}.".green if not_changes_needed.present?
    puts "Actualización finalizada con un total de #{errors.size} errores".yellow.swap if errors.present?
    puts 'Actualización finalizada sin errores'.green.swap unless errors.present?
  end

  desc 'Reassign selected invoices'
  task reassign_selected_invoices: :environment do
    errors = []
    puts '=== Iniciando Actualización ==='.green.swap
    duemint = DuemintService.new
    csv = CSV.read('lib/data/duemint_invoices_reassignment.csv', headers: true)
    csv.each do |row|
      begin
        invoice = Invoice.find_by(duemint_reference: row['duemintId'].to_i)
        new_emit_date = Date.new(row['año'].to_i, row['mes'].to_i, 1)
        if invoice.try(:company_id) == row['company.id'].to_i
          invoice.update(emit_date: new_emit_date)
          next puts "Actualización innecesaria para FACTURA: #{row['duemintId']}".cyan
        end

        unless invoice.present?
          next errors << row['duemintId'] if row['company.id'].to_i.zero?

          puts "Creando nueva FACTURA: #{row['duemintId']}".yellow
          invoice =
            Invoice.create(duemint_reference: row['duemintId'],
                           emit_date: new_emit_date,
                           company_id: row['company.id'].to_i)
        end

        next errors << row['duemintId'] unless invoice.present?

        puts "ACTUALIZANDO INVOICE ID:#{invoice.duemint_reference} PARA COMPAÑÍA: #{invoice.company.name}".yellow.swap
        duemint_data = duemint.document_by_client(duemint_reference: row['duemintId'])
        invoice.update(company_id: row['company.id'].to_i,
                       paid_amount: duemint_data['paidAmount'],
                       paid_date: duemint_data['paidDate'],
                       taxes: duemint_data['taxes'],
                       net: duemint_data['net'],
                       notes: duemint_data['notes'],
                       gloss: duemint_data['gloss'],
                       due_date: duemint_data['dueDate'],
                       number: duemint_data['number'],
                       state: duemint.document_state(duemint_data['status']),
                       files: { pdf: duemint_data['pdf'],
                                xml: duemint_data['xml'],
                                url: duemint_data['url'] })
      rescue StandardError => e
        puts "ERROR FACTURA #{row['duemintId']}\nMESSAGE: #{e.message}".red.swap
        errors << row['duemintId']
      end
    end
    File.write('lib/data/duemint_invoices_reassignment_errors.txt', errors.join("\n")) if errors.present?
    puts "Actualización finalizada con un total de #{errors.size} errores".yellow.swap if errors.present?
    puts 'Actualización finalizada sin errores'.green.swap unless errors.present?
  end
end
