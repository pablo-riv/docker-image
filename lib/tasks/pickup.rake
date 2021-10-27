namespace :pickup do
  desc 'Update pickup not retired status'
  task update_no_retired_status: :environment do
    today_pickups = Pickup.where("schedule ->> 'date' = ? AND status = ?", Date.current.to_s, 0).includes(packages: :packages_pickups)
    today_pickups.map do |pickup|
      packages = pickup.packages
      unshipped = packages.select('packages_pickups.shipped').reject(&:shipped).size
      status =
        if packages.size == unshipped
          'no_retired'
        elsif unshipped.positive?
          'shipped_with_issues'
        else
          'shipped'
        end
      pickup.update_columns(status: status)
    end
  end

  task generate_manifest: :environment do
    Pickup.daily_pickups.find_each(batch_size: 20).each do |pickup|
      begin
        pickup.generate_manifest
      rescue StandardError => e
        error_message = "PickupRake#generate_manifest - ERROR: #{e.message}\nBUGTRACE: #{e.backtrace}"
        puts error_message.red
      end
    end
  end
end
