namespace :company_segment do
  desc 'Create default company segments'
  task create_default_company_segments: :environment do
    puts '=== INIT TASK ==='.green
    default_company_segments = [
      { shipments_min: 0, shipments_max: 20, name: '0 - 20' },
      { shipments_min: 21, shipments_max: 60, name: '21 - 60' },
      { shipments_min: 61, shipments_max: 200, name: '61 - 200' },
      { shipments_min: 201, shipments_max: 400, name: '201 - 400' },
      { shipments_min: 401, shipments_max: 2000, name: '401 - 2000' },
      { shipments_min: 2001, shipments_max: 10_000_000, name: '2001 o más' }
    ]
    begin
      CompanySegment.create!(default_company_segments)
    rescue StandardError => e
      log_message = "Error: #{e.message}\nBUGTRACE: #{e.backtrace.first(3).join("\n")}"
      puts log_message.red
    end
    puts '=== END OF TASK ==='.green
  end
end
