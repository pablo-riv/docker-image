require 'mixpanel-ruby'

class MixpanelService
  TRACKED_PATHS = ['get_prices'].freeze
  def self.tracker(req: nil, source: '', data: {}, result: {}, status: 'success', account: {})
    return unless Rails.configuration.mixpanel_enable.to_s == 'true'
    return unless allowed_track(source)

    account_id = account.present? ? account.id : 'unknown'
    user_data = {
      'Country' => req.try(:location).try(:country),
      '$city' => req.try(:location).try(:city),
      'Path' => req.try(:path),
      '$ip' => req.try(:location).try(:ip),
      '$browser' => req.try(:user_agent),
      'type' => req.try(:method),
      '$email' => account.try(:email),
      '$first_name' => account.try(:full_name),
      '$company_id' => account.current_company.id,
      '$result' => result,
      '$status' => status
    }
    location_data = req.try(:location).try(:data) || {}
    track = new.tracker
    track.people.set(account_id, user_data)
    track.track(account_id, source, user_data.merge(location_data))
    Rails.logger.info "MixpanelService Track Event: #{source}: ".green.swap
  rescue StandardError => e
    Rails.logger.info "MixpanelService Error: #{source}\nError: #{e.message}\nBUG_TRACE: #{e.backtrace}".red
    Sneakers.logger.info "MixpanelService Error: #{source}\nError: #{e.message}\nBUG_TRACE: #{e.backtrace}".red
    Slack::Mixpanel.new&.mixpanel_error(message: "MixpanelService Error: #{source}\nError: #{e.message}\nBUG_TRACE: #{e.backtrace[0]}")
  end

  def self.allowed_track(tracked_request)
    TRACKED_PATHS.include?(tracked_request)
  end

  def initialize
    @token = Rails.configuration.mixpanel_token
  end

  def tracker
    Mixpanel::Tracker.new(@token)
  end

  def track
    tracker
  end
end
