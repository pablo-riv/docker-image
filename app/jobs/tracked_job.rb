class TrackedJob < ApplicationJob

  def track_action
    return unless Rails.configuration.mixpanel_enable.to_s == 'true'
    puts arguments

    company = arguments.find { |arg| arg.is_a?(Company) }
    package = arguments.find { |arg| arg.is_a?(Package) }

    company = package.try(:company) if company.blank?
    account = company.try(:default_account) unless company.blank?

    tracked_instance = self.class.name

    MixpanelService.tracker(nil, tracked_instance, account, '')
    puts 'tracking event'
  end
end
