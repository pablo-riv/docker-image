module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_account

    def connect
      self.current_account = find_verified_account
      logger.add_tags 'ActionCable', current_account.email
    end

    protected

    def find_verified_account # this checks whether a account is authenticated with devise
      if verified_account = env['warden'].user
        verified_account
      else
        reject_unauthorized_connection
      end
    end
  end
end