namespace :dhl do
    desc 'update dhl for available communes'
    task update: :environment do
      Commune.all.each do |c|
        c.couriers_availables["dhl"] = c.couriers_availables["correoschile"]
        c.save
      end
      puts "Communes for dhl availables updated!"
    end
  end
  