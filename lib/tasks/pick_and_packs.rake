namespace :pickup_and_pack do
  desc 'generate_update_manifest pickup not retired status'
  task generate_update_manifest: :environment do
    time = Time.now
    pick_and_packs = PickAndPacks::ByCuttingHour.new(time).pick_and_packs
    pickups = Pickup.where(pick_and_pack_id: pick_and_packs.pluck(:id))
    if pickups.blank?
      puts "#{I18n.t('pickups.messages.not_found_manifest_generation')} - #{time}".blue.swap
    else
      errors_generate_manifest = []
      pickups.each do |pickup|
        begin
          pickup.generate_manifest
        rescue StandardError => e
          errors_generate_manifest << "Pickup #{pickup.id} error: #{e.message}"
        end
      end
      puts "#{I18n.t('pickups.messages.manifest_generation_finished')} - #{time}".blue.swap
      errors_generate_manifest.each { |e| puts e.yellow } if errors_generate_manifest.present?
      puts "#{errors_generate_manifest.size} errors".yellow.swap if errors_generate_manifest.present?
      puts I18n.t('pickups.messages.manifest_generation_success').green.swap unless errors_generate_manifest.present?
    end
  end
end
