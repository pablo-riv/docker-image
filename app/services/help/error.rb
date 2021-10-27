module Help
  module Error
    class ZendeskError < ::StandardError; end
    class NoTicketFoundException < ZendeskError; end

  end
end
