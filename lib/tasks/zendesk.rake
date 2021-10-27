namespace :zendesk do
  desc 'Extract tickets by date range'
  task download_tickets: :environment do
    begin
      next_page = ''
      until next_page.nil?
        response = Zendesk::ZendeskService.new.sync_tickets_by_organization(next_page)
        response['tickets'].each do |ticket|
          comments = Zendesk::ZendeskService.new(ticket_id: ticket['id']).extract_comments
          Zendesk::ZendeskService.new(ticket: ticket.merge(from_zendesk: true, comments: comments).with_indifferent_access).generate_or_update_ticket
        end
        next_page = response['next_page'].nil? ? response['next_page'] : response['next_page'].split('json').last
      end
    rescue => e
      puts "Error: #{e.message}"
    end
  end

  desc 'update tickets on Shipit'
  task update_tickets: :environment do
    Support.where.not(status: ["closed","Cerrado","solved","Resuelto"], provider_id: nil).each do |t|
      begin
        previous_status = t.status
        remote_ticket = Zendesk::ZendeskService.new({ticket: t}).remote_ticket
        raise if remote_ticket.is_a?(String)

        t.update!(status: remote_ticket[:status])
        puts "Ticket #{t.id} updated!\nPrevious status: #{previous_status}\nCurrent status: #{t.status}"
      rescue StandardError => _e
        puts "Error: Ticket #{t.id} no pudo ser actualizado en Shipit\nError reponse: #{remote_ticket}"
      end
    end
  end

  desc 'Add public key to comment for show or hide to client'
  task add_public_key_to_comment: :environment do
    total_tickets = Support.count
    iteration = 1
    Support.all.each do |support|
      puts "Actualizando: #{iteration}/#{total_tickets}"
      begin
        comments = Zendesk::ZendeskService.new(ticket_id: (support.ticket_id || support.provider_id.to_i)).extract_comments
        ticket = Zendesk::ZendeskService.new(ticket: { comments: comments, ticket_id: (support.ticket_id || support.provider_id.to_i) })
        support.update_columns(messages: ticket.messages)
      rescue => e
        puts "Ticket #{support.id}, no actualizado. Error: #{e.message}"
        iteration += 1
        next
      end
      iteration += 1
    end
  end

  desc 'Sync tickets in db core'
  task sync_last_tickets: :environment do
    begin
      response = Zendesk::ZendeskService.new.sync_tickets_by_organization('')
      next_page = "?page=#{(response[:count]/100) - 51}"
      progress = 1
      until next_page.nil?
        puts "Page: #{next_page}"
        response = Zendesk::ZendeskService.new.sync_tickets_by_organization(next_page)
        response['tickets'].each do |ticket|
          puts "Ticket: #{ticket['id']}. Progress: #{progress}/5100"
          comments = Zendesk::ZendeskService.new(ticket_id: ticket['id']).extract_comments
          Zendesk::ZendeskService.new(ticket.merge(from_zendesk: true, comments: comments).with_indifferent_access).generate_or_update_ticket
          progress += 1
        end
        next_page = response['next_page'].nil? ? response['next_page'] : response['next_page'].split('json').last
      end
    rescue => e
      puts "Error: #{e.message}"
    end
  end

  desc 'Map company id to tickets'
  task set_company_id: :environment do
    accounts_problem = []
    Support.all.each do |ticket|
      begin
        next unless ticket.account_id.present?
        next if accounts_problem.include?(ticket.account_id)

        ticket.update_columns(company_id: Account.unscoped.find(ticket.account_id).current_company.id)
      rescue StandardError => _e
        puts "No se pudo setear company_id a la cuenta de id: #{ticket.account_id}"
        accounts_problem << ticket.account_id
        next
      end
    end
  end

  desc 'Map organization id to companies'
  task set_organization_id: :environment do
    Account.unscoped.all.each do |account|
      begin
        company = account.current_company
        raise 'Cuenta sin zendesk_id' unless account.zendesk_id.present?
        
        response = Zendesk::Api.new(account.zendesk_id).author
        raise 'No fue posible obtener el usuario desde la API de Zendesk' if response.is_a?(String)

        company.update_columns(zendesk_organization_id: response[:organization_id])
      rescue StandardError => e
        puts "No fue posible setear organization_id de la cuenta\nEmail: #{account.email} | ID: #{account.id}\nError: #{e.message}"
        next
      end
    end
  end
end
