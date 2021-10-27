module Zendesk
  module Authenticator
    def auth
      { username: Rails.configuration.zendesk[:email], password: Rails.configuration.zendesk[:password] }
    end
  end
end
