require 'json'

namespace :migrate do
  desc 'migrate accounts'
  task accounts: :environment do
    data = JSON.parse(File.read("#{Rails.root}/lib/data/accounts.json"))
    data['data'].each do |e_commerce|
      commune = Commune.find_by(name: e_commerce['commune_name'].upcase)
      puts "💪 Comuna encontrada #{commune.name}".blue unless commune.nil?
      puts "😭 Comuna NO encontrada #{e_commerce['commune_name'].upcase}".red if commune.nil?
      company = Company.find_by(name: e_commerce['name'])
      account = Account.find_by(email: e_commerce['email'])
      if company.blank? && account.blank?
        address = Address.new(complement: e_commerce['complement'],
                              number: e_commerce['number'],
                              street: e_commerce['street'],
                              commune_id: commune.id)
        address.save(validate: false)
        company = Company.new(name: e_commerce['name'],
                              run: e_commerce['run'],
                              email_contact: e_commerce['email'],
                              email_commercial: e_commerce['email_business'],
                              email_notification: e_commerce['email_notification'],
                              address_id: address.id)
        company.save(validate: false)
        company.generate_relation
        puts "🏢 created company: #{company.name}".green
        person = Person.new
        person.save(validate: false)
        account = company.accounts.new(email: e_commerce['email'],
                                       password: '12345678',
                                       password_confirmation: '12345678',
                                       person_id: person.id)
        account.save(validate: false)
        puts "🤖 created account id: #{account.email}".green
      else
        puts "🏢 getting company: #{company.name}".yellow if company
        puts "🏢 error: #{e_commerce}".red unless company
      end
    end
  end

  desc 'migrate accounts contact info'
  task accounts_contact_info: :environment do
    data = JSON.parse(File.read("#{Rails.root}/lib/data/accounts_contact_info.json"))
    logs = []
    data.each do |user|
      account = Account.find_by(email: user['email'])
      (logs << "😭\t Company nil #{user['email']}".red && next) if account.nil?
      company = account.entity_specific
      contact_name = user['contact_all_2'].split('-')[0]
      phone = user['contact_all_2'].split('-')[1]
      (logs << "😭\t Company nil #{user['email']}".red && next) if company.nil?
      logs <<
        if company.acting_as.update_columns(phone: phone, contact_name: contact_name)
          company.branch_offices.each { |bo| bo.acting_as.update_columns(phone: phone, contact_name: contact_name) }
          "😎\t Now has contact info for trello cards: #{company.contact_info}".green
        else
          "😭\t Hasn't contact info for trello cards: #{company.name}".red
        end
    end
    logs.each { |l| puts l }
  end

  desc 'Create branch offices for The Tie Club'
  task branch_offices_for_tie_club: :environment do |t|
    c = Company.find_by name: 'The Tie Club'
    c.branch_offices.create name: 'Garcia Madrid', phone: '56229454032', email_contact: 'contacto@thetieclub.cl'
    c.branch_offices.create name: 'Fossil Parque Arauco', phone: '5622 211 2437', email_contact: 'contacto@thetieclub.cl'
    c.branch_offices.create name: 'Fossil Casa Costanera', phone: '5622 24862048', email_contact: 'contacto@thetieclub.cl'
    c.branch_offices.create name: 'The Tie Club HQ', phone: '956496373', email_contact: 'contacto@thetieclub.cl'
    c.branch_offices.create name: 'Scalpers', phone: '56496373', email_contact: 'contacto@thetieclub.cl'
    c.branch_offices.create name: 'Uommo', phone: '+569 56496373', email_contact: 'contacto@thetieclub.cl'
    c.branch_offices.create name: 'Barbour', phone: '56229454032', email_contact: 'contacto@thetieclub.cl'
    c.branch_offices.create name: 'La Sebastiana', email_contact: 'contacto@thetieclub.cl'
  end

  desc 'update to original created_at date'
  task set_original_created_at: :environment do |t|
    data = JSON.parse(File.read("#{Rails.root}/lib/data/account_created_at.json"))
    data.each do |account|
      new_account = Account.find_by(email: account['email'])
      next if new_account.nil?
      if new_account.update_columns(created_at: account['created_at']) && new_account.entity.specific.update_columns(created_at: account['created_at'])
        puts "🏢 updating account and company: #{new_account.id} #{account['email']}".cyan
      else
        puts "🏢 not found account: #{account['email']}".red
      end
    end
  end

  desc 'Create address for packages with address.nil? from v1'
  task restore_packages_addresses: :environment do
    # IF THE MIGRATE IS over addresses-for-packages.json, REMOVE +1000 ON PACKAGE ID (ids with offset of the last migration)
    #packages_addresses = JSON.parse(File.read("#{Rails.root}/lib/data/addresses-for-packages.json")) # ids < 73066
    #packages_addresses = JSON.parse(File.read("#{Rails.root}/lib/data/addresses-for-packages2.json")) # ids >= 73066 .. 77147
    packages_addresses = JSON.parse(File.read("#{Rails.root}/lib/data/addresses-for-packages3.json")) # ids >= 77148 .. 78861
    total_count = packages_addresses.count
    errors = []
    packages_addresses.each_with_index do |package_address, i|
      debug_msg = "(#{i+1}/#{total_count}) Package #{package_address['id'] + 1000} - #{package_address['commune'].upcase}: "
      commune = Commune.find_by('UPPER(name) = ?', package_address['commune'].upcase)
      if commune.blank?
        errors.push [package_address['id'], package_address['commune'], 'Comuna no encontrada'] unless package_address['commune'] == 'Unknown'
      else
        package = Package.unscoped.find_by(id: (package_address['id'] + 1000))
        if package.blank?
          errors.push [package_address['id'], package_address['commune'], 'Package no encontrado']
        elsif package.address.blank?
          if package.build_address(commune_id: commune.id, street: package_address['street'], number: package_address['number'], complement: package_address['complement']).save
            debug_msg += "Creado correctamente".green
          else
            errors.push [package_address['id'], package_address['commune'], 'Address no se creó']
          end
        else
          errors.push [package_address['id'], package_address['commune'], 'Address ya existía']
        end
      end
      puts debug_msg
    end
    puts "#{errors.count} Errores: ".red
    puts errors
  end

  desc 'Migrate packages from v1 without address'
  task packages: :environment do
    # comment callbacks (:set_tracking y :set_price) and validations (:destiny, :approx_size, :packing, :shipping_type) in package.rb before
    # restore_packages_addresses rake task must be triggered after this rake to associate addresses to migrated packages
    #packages1 = JSON.parse(File.read("#{Rails.root}/lib/data/packages1.json")) # ids from 224 to 29999 (2016-07-19) [22772]
    #packages2 = JSON.parse(File.read("#{Rails.root}/lib/data/packages2.json")) # ids from 30002 to 52525 (2016-10-31) [19484] 270894 NULL
    #packages3 = JSON.parse(File.read("#{Rails.root}/lib/data/packages3.json")) # ids from 52526 to 73065 (2016-12-20 01:07:45) [15629] 219062 NULL (null email)
    #packages4 = JSON.parse(File.read("#{Rails.root}/lib/data/packages4.json")) # ids from 73066 to 77019 (2017-01-09 03:49:54) [3415]
    #packages5 = JSON.parse(File.read("#{Rails.root}/lib/data/packages5.json")) # ids from 73153 to 77147 (2017-01-12 19:28:40) [182] only with email conflicts
    #packages6 = JSON.parse(File.read("#{Rails.root}/lib/data/packages6.json")) # ids from 77148 to 78861 (2017-03-01 03:52:20) [1530] (Monoi,HBC,TieClub,Williot,INNOVATEK,Nboga,Shipit)
    monoi_packages = JSON.parse(File.read("#{Rails.root}/lib/data/monoi_packages_2017-03_2017-04.json")) # monoi packages
    #packages5: packages from v1 with id > 73065 and user.id in (442, 408, 170, 461, 130, 295, 262, 447, 459, 407, 434, 437, 440, 411, 410, 424, 463).
    packages = monoi_packages
    packages_count = packages.count
    errors = []
    packages.each_with_index do |package, i|
      next unless Package.unscoped.where(id: package['id']).last.blank?
      account = Account.find_by(email: package['e_commerce_email'])
      branch_office_id = account.nil? ? 1 : account.entity_specific.default_branch_office.id
      debug_msg = "(#{i+1}/#{packages_count}) #{package['id']}: "
      package_attributes = {
        'id' => package['id'],
        'branch_office_id' => branch_office_id,
        'pickup_id' => package['pickup_id'],
        'full_name' => package['full_name'],
        'email' => package['email'],
        'cellphone' => package['cellphone'],
        'length' => package['length'],
        'width' => package['width'],
        'height' => package['height'],
        'weight' => package['weight'],
        'approx_size' => package['approx_size'],
        'volume_ranking' => package['volume_ranking'],
        'reference' => package['reference'][0..11],
        'is_payable' => package['is_payable'],
        'is_fragile' => package['is_fragile'],
        'is_wrapper_paper' => package['is_wrapper_paper'],
        'is_reachable' => package['is_recheabe'],
        'is_printed' => package['is_printed'],
        'is_paid_shipit' => package['is_paid_shipit'],
        'is_returned' => package['is_returned'],
        'is_available' => package['is_available'],
        'is_archive' => package['archive'],
        'is_exception' => package['exception'],
        'is_mail_to_receiver' => package['mail_to_receiver'],
        'courier_for_entity' => package['courier'],
        'courier_for_client' => package['courier_shipit'],
        'courier_type' => package['courier_type'],
        'comments' => package['comments'],
        'reason' => package['reason'],
        'serial_number' => package['serial_number'],
        'items_count' => package['items_count'],
        'product_type' => package['product_type'],
        'tracking_number' => package['tracking_number'],
        'shipping_price' => package['shipping_price'],
        'shipping_cost' => package['shipping_cost'],
        'shipping_type' => 'Normal',
        'total_price' => package['total_price'],
        'shipit_code' => package['shipit_code'],
        'trello_item' => package['trello_item'],
        'parent_ot' => package['parent_ot'],
        'has_ot' => package['has_ot'],
        'box_type' => package['box_type'],
        'packing' => 'Sin empaque',
        'sell_type' => package['sell_type'],
        'sku_supplier' => package['sku_supplier'],
        'supplier_name' => package['supplier_name'],
        'craftman_state' => package['craftman_state'],
        'voucher_price' => package['voucher_price'],
        'pickup_distance' => package['pickup_distance'],
        'created_at' => Time.zone.parse(package['created_at']) - 3.hour,
        'updated_at' => Time.zone.parse(package['updated_at']) - 3.hour,
        'status' => package['shipit_state'],
        # 'inventory_activity' => package['inventory_activity'],
        'destiny' => 'Domicilio',
        'material_extra' => package['material_extra'],
        'v2' => false
      }
      package = Package.new(package_attributes)
      if package.save
        debug_msg += '💪 Package guardado'.green
      else
        debug_msg += "😭 Package no guardado #{package.errors.full_messages}".red
        errors.push package['id']
      end
      puts debug_msg
    end
    puts "#{errors.count} errores: ".red
    puts errors
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE packages_id_seq RESTART WITH #{Package.last.id.to_i + 1};")
  end

  desc 'Migrate packages from v1 without address'
  task find_monoi_packages: :environment do
    monoi_packages = JSON.parse(File.read("#{Rails.root}/lib/data/monoi_packages_2017-03_2017-04.json")) # monoi packages
    packages = monoi_packages
    packages_count = packages.count
    errors = []
    packages.each_with_index do |package, i|
      pas = Package.unscoped.where(id: package['id']).last
      puts pas.blank? ? "(#{i}/#{packages_count}): #{package['id']} not found".blue : "(#{i}/#{packages_count}): #{package['id']} found".yellow
    end
  end

  desc 'Update packages from october, november and dicember'
  task update_packages: :environment do
    updated_packages = JSON.parse(File.read("#{Rails.root}/lib/data/update_packages.json"))
    errors = []
    updated_packages.each_with_index do |package, i|
      p = Package.unscoped.find_by(id: package['id'])

      if p.blank?
        errors.push [package['id'], 'No existe']
      else
        package_attributes = {
              'full_name' => package['full_name'],
              'email' => package['email'],
              'cellphone' => package['cellphone'],
              'length' => package['length'],
              'width' => package['width'],
              'height' => package['height'],
              'weight' => package['weight'],
              'approx_size' => package['approx_size'],
              #'volume_price' => package['volume_ranking'],
              'reference' => package['reference'],
              'is_payable' => package['is_payable'],
              'is_fragile' => package['is_fragile'],
              'is_wrapper_paper' => package['is_wrapper_paper'],
              'is_reachable' => package['is_recheabe'],
              'is_printed' => package['is_printed'],
              'is_paid_shipit' => package['is_paid_shipit'],
              'is_returned' => package['is_returned'],
              'is_available' => package['is_available'],
              'is_archive' => package['archive'],
              'is_exception' => package['exception'],
              'is_mail_to_receiver' => package['mail_to_receiver'],
              'courier_for_entity' => package['courier'],
              'courier_for_client' => package['courier_shipit'],
              'courier_type' => package['courier_type'],
              'comments' => package['comments'],
              'reason' => package['reason'],
              'serial_number' => package['serial_number'],
              'items_count' => package['items_count'],
              'product_type' => package['product_type'],
              'tracking_number' => package['tracking_number'],
              'shipping_price' => package['shipping_price'],
              'shipping_cost' => package['shipping_cost'],
              'total_price' => package['total_price'],
              'shipit_code' => package['shipit_code'],
              'trello_item' => package['trello_item'],
              'parent_ot' => package['parent_ot'],
              'has_ot' => package['has_ot'],
              'box_type' => package['box_type'],
              'packing' => package['packing'],
              'sell_type' => package['sell_type'],
              'sku_supplier' => package['sku_supplier'],
              'supplier_name' => package['supplier_name'],
              'craftman_state' => package['craftman_state'],
              'voucher_price' => package['voucher_price'],
              'pickup_distance' => package['pickup_distance'],
              'status' => package['shipit_state'],
              'material_extra' => package['material_extra']
            }
        p.assign_attributes(package_attributes)
        if p.changed?
          puts "Package #{p.id} #{p.created_at} ".green
          puts p.changes
          p.save(validate: false)
        else
          #puts 'No ha cambiado'
        end
      end
    end
    puts "#{errors.count} ERRORES: ".red
    puts errors
  end

  desc 'Set original password from old core-app to shipit-core'
  task set_original_password: :environment do |t|
    data = JSON.parse(File.read("#{Rails.root}/lib/data/accounts_with_password.json"))
    logs = []
    data.each do |account|
      new_account = Account.find_by(email: account['email'])
      next if new_account.nil?
      update = "UPDATE accounts SET encrypted_password = '#{account['password']}' WHERE email = '#{account['email']}'"
      logs <<
        if ActiveRecord::Base.connection.execute(update)
          "🏢 updating account: #{new_account.id} #{account['email']}".cyan
        else
          "🏢 not found account: #{account['email']}".red
        end
    end
    logs.each { |l| puts l }
  end

  desc 'Migrate the nboga data from the old core app'
  task migrate_nboga_packages: :environment do |t|
    data = JSON.parse(File.read("#{Rails.root}/lib/data/nboga.json"))
    errors = []
    data.each do |package|
      new_package = Package.find_by(reference: package['reference'])
      branch_office = BranchOffice.find_by(name: package['supplier_name'])

      unless new_package.blank?
        new_package.update_columns(branch_office_id: (branch_office.blank? ? 23 : branch_office.id))
        puts "Package #{new_package.reference} fue actualizado al branch office #{new_package.branch_office.name}"
      else
        package_create = {  branch_office_id: (branch_office.blank? ? 23 : branch_office.id),
                            full_name: package['full_name'],
                            email: package['email'],
                            cellphone: package['cellphone'],
                            length: package['length'],
                            width: package['width'],
                            height: package['height'],
                            weight: package['weight'],
                            reference: package['reference'],
                            shipping_type: package['shipping_time'],
                            destiny: package['branch_office'],
                            approx_size: package['approx_size'],
                            is_payable: package['is_payable'],
                            is_fragile: package['is_fragile'],
                            is_wrapper_paper: package['is_wrapper_paper'],
                            is_reachable: package['is_recheabe'],
                            is_printed: package['is_printed'],
                            is_paid_shipit: package['is_paid_shipit'],
                            is_returned: package['is_returned'],
                            is_available: package['is_available'],
                            is_archive: package['archive'],
                            is_exception: package['exception'],
                            is_mail_to_receiver: package['mail_to_receiver'],
                            courier_for_entity: package['courier'],
                            courier_for_client: package['courier_shipit'],
                            courier_type: package['courier_type'],
                            comments: package['comments'],
                            reason: package['reason'],
                            serial_number: package['serial_number'],
                            items_count: package['items_count'],
                            product_type: package['product_type'],
                            tracking_number: package['tracking_number'],
                            shipping_price: package['shipping_price'],
                            shipping_cost: package['shipping_cost'],
                            total_price: package['total_price'],
                            shipit_code: package['shipit_code'],
                            trello_item: package['trello_item'],
                            parent_ot: package['parent_ot'],
                            has_ot: package['has_ot'],
                            box_type: package['box_type'],
                            packing: (package['packing'].blank? ? 'Sin empaque' : package['packing']),
                            sell_type: package['sell_type'],
                            sku_supplier: package['sku_supplier'],
                            supplier_name: package['supplier_name'],
                            craftman_state: package['craftman_state'],
                            voucher_price: package['voucher_price'],
                            pickup_distance: package['pickup_distance'],
                            status: package['shipit_state'],
                            material_extra: package['material_extra'],
                            address_attributes: {
                              commune_id: Commune.where(name: package['commune_name']).blank? ? 1 : Commune.where(name: package['commune_name']).first.id,
                              complement: package['complement'],
                              number: package['number'],
                              street: package['street'],
                              created_at: package['created_at']
                            }
                          }
            a = Package.new(package_create)
            puts "Package #{a.reference} creado para el branch_office #{a.branch_office.name}" if a.save(validate: false)
      end
    end
  end

  desc 'Migrate mongo order_service to postgres order model'
  task download_all_orders: :environment do
    OrderService.all.group_by(&:company_id).each do |company, orders|
      company = Company.find_by(id: company)
      next unless company.present?

      account = company.current_account
      # api = OrderApi.new(account: account,
      #                    company: company,
      #                    orders: orders,
      #                    email: account.email,
      #                    authentication_token: email.authentication_token)
      api.post
    end
  end
end
