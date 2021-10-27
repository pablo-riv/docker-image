class IntegrationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "integration_downloads_#{ current_account.try(:entity_id) }"
  end
end