class SyncronizeSupportJob < ApplicationJob
  queue_as :default

  def perform(current_account)
    support = Help::ZendeskTicket.new(account: current_account, company: current_account.current_company)
    support.syncronize
  end
end
