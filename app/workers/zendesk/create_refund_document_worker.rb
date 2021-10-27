class CreateRefundDocumentWorker
  include Sneakers::Worker
  from_queue 'core.refund_document_synchronize_zendesk'

  def work(data)
    attributes = JSON.parse(data)
    Sneakers.logger.info "Prepare file's data: #{attributes}".green
    RefundDocumentWorker.perform_async(attributes['id'].to_i)
    ack!
  rescue StandardError => _e
    ack!
  end
end
