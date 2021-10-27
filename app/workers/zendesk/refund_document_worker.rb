class RefundDocumentWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, backtrace: true

  sidekiq_retry_in do |_count, exception|
    puts "Cant create file: #{exception.message}".yellow
    900 # Time in seconds, 15 minutes
  end

  def perform(id)
    puts "Document id: #{id}"
    refund_document = RefundDocument.find_by(id: id)
    Sneakers.logger.info "Prepare document: #{refund_document&.document_file_name}".green
    response = Zendesk::Api.new.update_attachment(Paperclip.io_adapters.for(refund_document&.document).read,
                                                  filename(refund_document, id))
    refund_document.update zendesk_token_upload: response[:token]
  end

  def filename(document, id)
    raise I18n.t('zendesk.validations.filename') if document.nil?

    "#{document&.refund_id}_#{id}#{File.extname(document&.document_file_name)}"
  end
end
