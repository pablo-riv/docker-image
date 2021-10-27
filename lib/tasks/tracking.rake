namespace :tracking do
  desc 'removing packages with inconsistent package_id'
  task delete_with_inconsistentes_package_id: :environment do
    Tracking.joins('LEFT JOIN packages ON trackings.package_id = packages.id').where('packages.id IS NULL').select('trackings.id').destroy_all
  end

  desc 'removing duplicate trackings'
  task delete_duplicate_trackings: :environment do
    puts '[BEGIN] Deleting duplicate tracking'.green
    puts '======================================='.green

    puts 'Deleting trackings with same number'.blue

    package_ids_with_same_tracking_number = Tracking.where.not(package_uuid: nil)
                                              .group('package_id, courier_symbol, number').having('count(package_id) > 1')
                                              .select('package_id, number').pluck(:package_id, :number)
    package_ids_with_same_tracking_number.each do |package_with_same_tracking|
      trackigs_with_same_number = Tracking.includes(:statuses)
                                    .where(package_id: package_with_same_tracking[0], number: package_with_same_tracking[1])
                                    .order(created_at: :desc).to_a
      tracking = trackigs_with_same_number.shift
      puts "Unifying tracking_number: #{tracking.number}".yellow
      trackigs_with_same_number.each do |other_tracking|
        statuses_to_move = other_tracking.statuses.select { |status| status unless tracking.statuses.reload.pluck(:courier_status).include?(status.courier_status) }
        statuses_to_move.each do |status_to_move|
          status_to_move.update(tracking: tracking)
        end
        other_tracking.reload
        other_tracking.destroy
      end
    end
    puts 'Deleting trackings duplicated'.blue

    package_ids_with_trackings_duplicate = Tracking.where.not(package_uuid: nil).group('package_id').having('count(package_id) > 1').select('package_id').pluck(:package_id)
    package_ids_with_trackings_duplicate.each do |package_id|
      begin
        puts "Deleting duplicate tracking for package_id: #{package_id}".yellow
        package = Package.find(package_id)
        Tracking.where(package_id: package_id).where.not(number: package.tracking_number).destroy_all
      rescue StandardError => e
        puts "Error al procesar trackings para el package ID: #{package_id}".red.swap
      end
    end
    puts '======================================='.green
    puts '[END] Deleting duplicate tracking'.green
  end
end
