class ChangePackageAddressWorker
  include Sneakers::Worker
  from_queue 'core.change_package_address'

  def work(data)
    attributes = JSON.parse(data)
    kind = 'change_address_with_'
    Sneakers.logger.info "Prepare ticket's data: #{attributes}".green
    %w[client courier].map do |type|
      kind_type = "#{kind}#{type}"
      CreateChangePackageAddressWorker.perform_async(type, attributes, kind_type)
    end
    ack!
  rescue StandardError => e
    ack!
  end
end
