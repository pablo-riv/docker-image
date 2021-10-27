namespace :pipedrive do
  desc 'Generate CSV with deals'
  task persons: :environment do
    object = JSON.parse(File.read("#{Rails.root}/lib/data/persons.json"))
    grouped_data = object['data'].group_by { |object| object['owner_name'] }
    report = CSV.generate(encoding: 'UTF-8'.encoding) do |csv|
      csv << ['Nombre', 'Correos', 'Telefonos', 'Empresa', 'Nombre KAM', 'Email KAM']
      grouped_data.each do |owner, organizations|
        next unless organizations.present?

        csv << [deal['person_id']['name'],
        deal['person_id']['email'].pluck('value').join(', '),
        deal['person_id']['phone'].pluck('value').join(', '),
        deal['org_id']['name'],
        deal['user_id']['name'],
        deal['user_id']['email']]
      end
    end
    File.open("#{Rails.root}/public/deals.csv", 'w+b') do |f|
      f.write(report)
    end
  end
end
