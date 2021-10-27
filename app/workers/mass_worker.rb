class MassWorker
  include Sneakers::Worker
  from_queue 'pp.update_package', env: nil, ack: true

  def work(data)
    packages = JSON.parse(data)
    return unless packages['packages'].count.positive?
    packages['packages'].each do |package|
      Rails.logger.info { package['trello_item'].to_s.yellow }
      Sneakers::logger.info "mass_worker:here is a trello item to setup in #{package['id']} - #{package['trello_item']}".green
      if Package.find_by(id: package['id']).update_columns(pickup_id: package['pickup_id'], trello_item: package['trello_item'])
        Sneakers::logger.info "mass_worker: package updated with #{package['pickup_id']} and #{package['trello_item']}".green
        Rails.logger.info { "mass_worker:package =>  #{package}".cyan }
      end
    end
    ack!
  rescue StandardError => e
    Sneakers::logger.info "mass_worker: #{e.message}".red
    Rails.logger.info { "mass_worker: #{e.message}".red }
    ack!
  ensure
    ack!
  end
end
