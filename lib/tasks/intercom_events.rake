namespace :intercom_events do

  desc 'This task detect daily company request'
  task daily_requests: :environment do
    logs = []
    Company.find_each(batch_size: 30) do |company|
      packages = company.packages.today_packages_with_exception.joins(branch_office: :company)
      logs <<
        if company.daily_requests.create!(quantity: packages.count)
          "COMPANY: #{company.name} HAS #{packages.count} REQUEST TODAY".green
        else
          "COMPANY: #{company.name} HASN'T REQUEST TODAY".red
        end
    end
  end

  desc 'This task create event in intercom when clients has not request'
  task two_weeks_without_request: :environment do
    intercom = Intercom::Client.new(token: 'dG9rOjI3MmQ2ZDJlX2IxNzBfNGUzYl9iMjgwX2QxYTFmNDUwY2EzMDoxOjA=')
    Company.where(id: 886).each do |company| #find_each(batch_size: 30) do |company|
      packages = company.packages.where(created_at: ((Time.current - 2.weeks).beginning_of_day)..Time.current.end_of_day)
      next if packages.count.positive?

      event = intercom.events.create(
        event_name: 'two_weeks_without_request',
        created_at: Time.now.to_i,
        user_id: company.id,
        metadata: {

        }
      )
    end
  end
end