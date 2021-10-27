namespace :refund do
  desc 'Refund date correction'
  task date_correction: :environment do
    puts '### Start ###'
    Incidence.where(actable_type: 'LostParcel').each do |incidence|
      refund = incidence&.actable&.refund
      next if refund.blank?
      next unless %w[rejected approved].include?(refund.status)

      puts "REFUND ID #{refund.id}"
      refund.update(date: refund.updated_at.to_date)
    end
    puts '### End ###'
  end
end
