namespace :hubspot do
  desc 'Migrate companies'
  task migrate: :environment do
    abort 'Its not production environment' unless Rails.env == 'production'

    puts "TOTAL COMPANIES TO MIGRATE: #{Company.where(hubspot_contact_id: [nil, ''], hubspot_company_id: ['', nil]).count}".yellow.swap
    Company.where(hubspot_contact_id: [nil, '']).or(Company.where(hubspot_company_id: ['', nil])).find_each(batch_size: 10).each do |company|
      begin
        next if company.name.include?('test')
        next unless company.valid?

        generator = HubspotService::Generator.new(company: company, account: company.current_account)
        generator.create
      rescue => e
        puts e.message
      end
    end
  end

  desc 'Daily company / contacts update'
  task update: :environment do
    abort 'Its not production environment' unless Rails.env == 'production'

    Company.where.not(id: [1279, 1976, 1935, 780, 2388], hubspot_contact_id: [nil, '']).order(id: :desc).each do |company|
      begin
        next if company.name.include?('test')
        next unless company.valid?

        commercial = HubspotService::Generator.new(company: company, account: company.current_account)
        puts "UPDATE CONTACT/COMPANY: #{company.name}".cyan.swap
        commercial.update
      rescue => e
        puts e.message
      end
    end
  end
end
