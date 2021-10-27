namespace :prediction do
  desc 'Update prediction date in base operation date'
  task update_prediction: :environment do
    CSV.foreach("#{Rails.root}/public/predictive_dates_load.csv", headers: true) do |row|
      package = Package.find_by(id: row['id'])
      package&.prediction&.update(delivery_date: row['delivery_date'])
    end
  end
end
