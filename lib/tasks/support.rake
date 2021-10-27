namespace :support do

  desc 'It Syncronoze all Tickets by customers'
  task syncronize: :environment do
    Account.with_tickets_unsolved.find_each(batch_size: 5) do |account|
      support = Help::ZendeskTicket.new(account: account, company: account.entity_specific)
      support.syncronize
    end
  end
end
