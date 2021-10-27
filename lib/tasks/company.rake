namespace :company do
  desc 'Add origin'
  task add_origin: :environment do
    logs = []
    ids = Rails.cache.read("ids_to_migrate")
    companies = Company.left_outer_joins(:origins).where('origins.id IS NULL').where(id: ids).group('companies.id')
    companies.each do |company|
      if company.origins.size.zero?
        begin
          raise unless company.address.valid?
          next unless company.current_account.present?

          origin = company.origins.new(
            name: 'default',
            address_book_attributes: {
              company_id: company.id,
              full_name: company.current_account.full_name.strip.present? ? company.current_account.full_name : 'Sin nombre',
              phone: company.default_branch_office.phone,
              email: company.current_account.email,
              default: true,
              address_attributes: company.address.dup.attributes.except('id', 'created_at', 'updated_at')
            }
          )
          raise unless origin.save!

          logs << "COMPANY: #{company.name}, #{origin}".green.swap
        rescue => e
          puts e.message
        end
      else
        origin = company.origins.joins(:address_book).find_by(address_books: { default: true })
        if origin.nil?
          origin = company.origins.joins(:address_book).order(id: :asc).first
          origin.address_book.update_columns(default: true)
          logs << "COMPANY: #{company.name}, #{origin} UPDATED ORIGIN".green.swap
        else
          origin.address_book.address.update_columns(company.address.dup.attributes.except('id', 'created_at', 'updated_at'))
          logs << "COMPANY: #{company.name}, UPDATED ORIGIN".green.swap
        end
      end
    end
    logs.each { |l| puts l }
  end

  desc 'Add default branch office to default origin'
  task set_branch_office_to_origin: :environment do
    ids = Rails.cache.read("ids_to_migrate")
    companies = Company.left_outer_joins(:origins, :address_books).where(id: ids)
    companies.each do |company|
      next if company.address_books.size.zero?
      origin = company.origins.find_by('address_books.default = true')
      next if origin.blank?
      next unless origin.branch_office_id.blank?

      origin.update_columns(branch_office_id: company.branch_offices.find_by(is_default: true).id)
    end
  end

  desc 'Migrate dni and business turn'
  task migrate: :environment do
    logs = []
    CSV.foreach("#{Rails.root}/lib/data/companies.csv", headers: true) do |row|
      data = row.to_hash.with_indifferent_access
      company = Company.find_by(id: data[:id].to_i)
      next unless company.present?

      company.acting_as.update_columns(run: data[:dni])
      company.update_columns(business_turn: data[:business_turn])
      logs << company.name
    end
    logs.each { |l| puts l }
    puts logs.count
  end

  desc 'Update First and Second owner IDs'
  task update_owner_ids: :environment do
    puts 'READING CSV'.green.swap
    csv = File.read("#{Rails.root}/lib/data/new_owner_ids.csv")
    raise puts 'CSV not found'.red.swap unless csv.present?

    companies_updated = 0
    companies_not_found = []
    CSV.parse(csv, headers: true).each_with_index do |data, _index|
      data = data.to_hash.with_indifferent_access
      new_first_owner_required = data[:first_owner].to_i != data[:new_first_owner].to_i
      new_second_owner_required = data[:second_owner].to_i != data[:new_second_owner].to_i
      next puts "Company ID: #{data[:company_id]} doesn't require changes" unless new_first_owner_required && new_second_owner_required

      company = Company.find_by(id: data[:company_id].to_i)
      next companies_not_found << data[:company_id] unless company.present?

      company.update_columns(first_owner_id: data[:new_first_owner].to_i) if new_first_owner_required
      company.update_columns(second_owner_id: data[:new_second_owner].to_i) if new_second_owner_required
      companies_updated += 1
      puts "Company ID: #{data[:company_id]} updated successfully".blue
    end
    puts "#{companies_not_found.size} IDs in CSV couldn't be found, with the following values:\n[#{companies_not_found.join(',')}]".yellow.swap unless companies_not_found.size.zero?
    puts "#{companies_updated} companies have been updated successfully".green.swap
  end

  desc 'Generate default template emails notifications'
  task generate_template_emails: :environment do
    companies = Company.includes(:mail_notifications, :settings)
    companies.select { |company| company.mail_notifications.blank? && company.settings.find_by(service_id: 6).present? }
             .each(&:generate_default_buyer_notifications)
    puts '🎉'
  end
end
