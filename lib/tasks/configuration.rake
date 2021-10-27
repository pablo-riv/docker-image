namespace :configuration do
  desc 'Add bsale settings to sellers json'
  task set_bsale_default: :environment do
    Setting.all.each do |setting|
      fullit = setting.configuration['fullit']
      next if fullit.nil?
      sellers = fullit['sellers']
      next if sellers.nil?
      next if sellers.any? { |h| h['bsale'] }
      element = { bsale: { client_id: '' } }
      setting.configuration['fullit']['sellers'] << element
      configuration = setting.configuration
      if setting.update_columns(configuration: configuration)
        puts "configuration #{configuration} is updated :)".green
      else
        puts "configuration #{configuration} is not updated :()".red
      end
    end
  end

  desc 'Add shopify settings to sellers json'
  task set_shopify_default: :environment do
    Setting.all.each do |setting|
      fullit = setting.configuration['fullit']
      next if fullit.nil?
      sellers = fullit['sellers']
      next if sellers.nil?
      next if sellers.any? { |h| h['shopify'] }
      element = { shopify: { client_id: '', access_token: '', store_name: '' } }
      setting.configuration['fullit']['sellers'] << element
      configuration = setting.configuration
      if setting.update_columns(configuration: configuration)
        puts "configuration #{configuration} is updated :)".green
      else
        puts "configuration #{configuration} is not updated :()".red
      end
    end
  end

  desc 'Add api2cart settings to sellers json'
  task set_api2cart_default: :environment do
    Setting.all.each do |setting|
      fullit = setting.configuration['fullit']
      next if fullit.nil?
      sellers = fullit['sellers']
      next if sellers.nil?
      next if sellers.any? { |h| h['api2cart'] }
      element = { api2cart: { client_id: '', store_keys: [] } }
      setting.configuration['fullit']['sellers'] << element
      configuration = setting.configuration
      if setting.update_columns(configuration: configuration)
        puts "configuration #{configuration} is updated :)".green
      else
        puts "configuration #{configuration} is not updated :()".red
      end
    end
  end

  desc 'Add woocommerce settings to sellers json'
  task set_woocommerce_default: :environment do
    Setting.all.each do |setting|
      fullit = setting.configuration['fullit']
      next if fullit.nil?
      sellers = fullit['sellers']
      next if sellers.nil?
      next if sellers.any? { |h| h['woocommerce'] }
      element = { woocommerce: { client_id: '' } }
      setting.configuration['fullit']['sellers'] << element
      configuration = setting.configuration
      if setting.update_columns(configuration: configuration)
        puts "configuration #{configuration} is updated :)".green
      else
        puts "configuration #{configuration} is not updated :()".red
      end
    end
  end

  desc 'Add prestashop settings to sellers json'
  task set_prestashop_default: :environment do
    Setting.all.each do |setting|
      fullit = setting.configuration['fullit']
      next if fullit.nil?
      sellers = fullit['sellers']
      next if sellers.nil?
      next if sellers.any? { |h| h['prestashop'] }
      element = { prestashop: { client_id: '' } }
      setting.configuration['fullit']['sellers'] << element
      configuration = setting.configuration
      if setting.update_columns(configuration: configuration)
        puts "configuration #{configuration} is updated :)".green
      else
        puts "configuration #{configuration} is not updated :()".red
      end
    end
  end

  desc 'Add opencart settings to sellers json'
  task set_opencart_default: :environment do
    Setting.all.each do |setting|
      fullit = setting.configuration['fullit']
      next if fullit.nil?
      sellers = fullit['sellers']
      next if sellers.nil?
      next if sellers.any? { |h| h['opencart'] }
      element = { opencart: { client_id: '' } }
      setting.configuration['fullit']['sellers'] << element
      configuration = setting.configuration
      if setting.update_columns(configuration: configuration)
        puts "configuration #{configuration} is updated :)".green
      else
        puts "configuration #{configuration} is not updated :()".red
      end
    end
  end

  desc 'Add opencart settings to sellers json'
  task set_jumpseller_default: :environment do
    Setting.all.each do |setting|
      fullit = setting.configuration['fullit']
      next if fullit.nil?
      sellers = fullit['sellers']
      next if sellers.nil?
      next if sellers.any? { |h| h['jumpseller'] }
      element = { jumpseller: { client_id: '' } }
      setting.configuration['fullit']['sellers'] << element
      configuration = setting.configuration
      if setting.update_columns(configuration: configuration)
        puts "configuration #{configuration} is updated :)".green
      else
        puts "configuration #{configuration} is not updated :()".red
      end
    end
  end
end
