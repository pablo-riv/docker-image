class CreateRefundTicketWorker
  include Sneakers::Worker
  from_queue 'core.create_refund_ticket'

  def work(data)
    attributes = JSON.parse(data)
    Sneakers.logger.info "Prepare ticket's data: #{attributes}".green
    TicketWorker.perform_async('courier', attributes, 'lost_parcel')
    ack!
  rescue StandardError => _e
    ack!
  end
end
