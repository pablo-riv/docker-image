namespace :account do
  desc 'It generate contact on infusionsoft'
  task create_contact_infusion: :environment do
    #Account.all.each do |account|
      #Infusionsoft.new.create_or_update_contact(account)
    #end
  end

  desc 'Migrate new version of google sheets'
  task :migrate_spreadsheets, %i[init finish] => :environment do |_t, args|
    Account.where(id: args[:init].to_i..args[:finish].to_i).each do |account|
      SpreadsheetsJob.perform_later(account, 'V6')
    end
  end

  desc 'Update all zendesk_id to account'
  task add_zendesk: :environment do
    Account.where(zendesk_id: nil).each do |account|
      support = Help::ZendeskUser.new(account)
      support.find
      support.create unless support.user.present?
      begin
        account.update(zendesk_id: support.user.id)
        puts "ACCOUNT WITH ZENDESK: #{account.id}".green.swap
      rescue => e
        puts "EXCEPTION: #{e.message}".red.swap
      end
    end
  end

  desc 'rollback how to know shipit'
  task rollback_how_to_know: :environment do
    CSV.foreach("#{Rails.root}/lib/data/accounts.csv", headers: true) do |row|
      data = row.to_hash.with_indifferent_access
      account = Account.find_by(id: data[:id])
      next unless account.present?

      account.update_columns(how_to_know_shipit: { how_to_know: data[:how_to_know], from: data[:from].presence || '' })
    end
  end

  desc ''
  task add_origin: :environment do
    emails = ['demagiaycarton@gmail.com','demariechile@gmail.com','silvana@araf.cl','contacto@8-bits.cl','michele@uniqueshoes.cl','w.lecaros.h@gmail.com','gramirez.e@gmail.com','jesus@epic.cl','eguerra@posterhouse.cl','contacto@mariapompon.cl','silvia@craftbox.cl','cristobal@vitalmarket.cl','jgranifo@flexboards.cl','ssoza@restbar.cl','contacto@cadacosaensulugar.cl']
    Entity.where("lower(actable_type) = 'company'").each do |entity|
      next if emails.include?(entity.account.email)

      company = entity.specific
      address = entity.address
      account = entity.account
      next unless account.present? || company.present? || address.present?

      company.create_or_update_origin(account, company, address)
    end
  end
end
