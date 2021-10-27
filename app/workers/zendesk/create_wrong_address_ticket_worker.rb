class CreateWrongAddressTicketWorker
  include Sneakers::Worker
  from_queue 'core.proactive_monitoring_wrong_address'

  def work(data)
    attributes = JSON.parse(data)
    puts "attributes: #{attributes}"
    Sneakers.logger.info "Prepare ticket's data: #{attributes}".green
    tracking_label = upload_tracking_label(attributes['id'])
    attributes['zendesk_documents'] = tracking_label
    TicketWorker.perform_async('courier', attributes, 'wrong_address')
    ack!
  rescue StandardError => _e
    ack!
  end

  def update_tracking_label(id)
    url = Tracking.find_by(package_id: id)&.pack_pdf
    return if url.blank?

    Zendesk::Api.new.update_attachment(URI.parse(url).open(&:read),
                                       "etiqueta_#{id}.pdf")[:token]
  end
end
