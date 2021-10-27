class WebhookJob < TrackedJob
  queue_as :default

  def perform(packages)
    packages.each do |package|
      begin
        next unless package.persisted?

        package.dispatch_webhook(kind_of_call: 'push')
      rescue StandardError => e
        Slack::Ti.new({}, {}).alert('', "HANDLE ERROR AT LINE: 11 WebhookJob#perform\nERROR: #{e.message}\nBUGTRACE: #{e.backtrace.first(3)}")
      end
    end
  end
end
