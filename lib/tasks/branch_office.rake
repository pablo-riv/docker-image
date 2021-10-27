namespace :branch_office do

  desc 'Check area 1 and excecute job to assign area'
  task check_area: :environment do
    BranchOffice.left_outer_joins(:location).where('locations.area_id = 1').find_each(batch_size: 10).each do |branch_office|
      begin
        CheckAreaBranchOfficeJob.perform_now(branch_office)
      rescue => e
        puts "#{branch_office.name} - #{puts e.message}".green.swap
      end
    end
  end

  desc 'It update area id on branch_office location'
  task update_area: :environment do
    puts '============================================================'.yellow
    BranchOffice.includes(:location).each do |branch_office|
      address = branch_office.default_address
      if address.blank? || address.coords['latitude'].to_f == 0.0 && address.coords['longitude'].to_f == 0.0
        puts "Address; #{address.to_json}".red
        next
      end
      latlng = [address.coords['latitude'], address.coords['longitude']]
      area = Area.all.map { |a| a if RaycastServices::Calc.contains?(a.coords.map { |coord| { 'latitude' => coord['latitude'].to_f, 'longitude' => coord['longitude'].to_f } }, latlng.first, latlng.second) == 1 }.compact.first
      company = branch_office.company
      if area.blank?
        puts "😠\t AREA BLANK? #{area}".red
        puts "😠\t BRANCH OFFICE: #{branch_office.name}".red
        next
      else
        if branch_office.location.nil?
          branch_office.create_location(area_id: area.id)
        else
          branch_office.location.update_columns(area_id: area.id)
        end
        puts "😎\t ASSIGN TYPE MANUAL".green
        puts "😎\t BRANCH OFFICE: #{branch_office.name}".green
        puts "😎\t AREA: #{area.name}".green
      end
    end
    puts '============================================================'.yellow
  end

  desc 'Update all first Branch Office to default'
  task default: :environment do
    puts '============================================================'.yellow
    logs = []
    Company.includes(:branch_offices).each do |company|
      if company.branch_offices.length.zero? || company.address.blank?
        puts "Company: #{company.id} - #{company.name}".red
        puts "Address: #{company.address.to_json}".red
        next
      end
      address = { street: company.address.street,
                  commune_id: company.address.commune_id,
                  number: company.address.number,
                  complement: company.address.complement }
      logs <<
        if company.branch_offices.first.update_columns(is_default: true) && company.branch_offices.first.acting_as.create_address(address)
          "😎\t #{company.default_branch_office.name} IS DEFAULT".green
        else
          "😭\t SOME ERROR WITH #{company.branch_offices.first.to_json}\t OR Address: #{company.address.to_json}".red
        end
    end
    logs.each { |l| puts l }
    puts '============================================================'.yellow
  end
end
