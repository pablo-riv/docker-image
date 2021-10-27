if Rails.env.production?
  Bugsnag.configure do |config|
    config.api_key = 'b006625bdec34232577e8ae44ef4c3fb'
  end
end
