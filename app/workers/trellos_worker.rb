class TrellosWorker
  include Sneakers::Worker
  from_queue 'core.create_trello', env: nil, ack: true

  def work(data)
    data = JSON.parse(data)
    BranchOffice.where(id: data['branch_office_ids']).each(&:generate_trello_card)
    ack!
  rescue StandardError => e
    Sneakers::logger.info "trello_worker: #{e.message}".red
    Rails.logger.info { "trello_worker: #{e.message}".red }
    ack!
  ensure
    ack!
  end
end
