Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.asset_host = 'http://localhost:3000'

  # config.action_mailer.perform_deliveries = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  config.action_mailer.default_url_options = { host: 'localhost:3000' }
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.bootic = {
    client_id: '0526ade27f99a3b1bf21bb06ae631d5c',
    client_secret: '03bf60bb2a65d6f0cb626da986e8947e'
  }
  Paperclip.options[:command_path] = "/usr/local/bin/"
  config.paperclip_defaults = {
    storage: :s3,
    s3_region: ENV['AWS_REGION'],
    s3_credentials: {
      bucket: 'shipit-platform',
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    }
  }

  config.slack_token = 'xoxb-441973426945-634769395686-DT6zRzM3ns4Xcr3wkxzTnJZR'
  config.zendesk_token = '2a6b30db-a1f0-466b-a61a-91bc8c50a2e1'

  config.action_cable.url = 'ws://localhost:3000/cable'
  config.opit_endpoint = 'localhost:6000'
  config.fulfillment_endpoint = 'http://localhost:4000/api/'
  config.statuses_endpoint = 'http://localhost:9000/v/'
  config.rollbar_access_token = 'f102ef0db30b4f2798e63d7f5412bf41'
  # TCC COURIERS
  config.chilexpress = {
    name: 'Chilexpress',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/chilexpress.png',
    acronym: 'cxp',
    username: 'UsrShipit',
    password: '7$79TC69d65',
    tcc_number: '18564153',
    api_key: ''
  }

  config.starken = {
    name: 'Starken',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/starken.png',
    acronym: 'stk',
    company_id: '76499449',
    username: '76499449',
    password: '7649',
    company_checker: '3',
    checking_account: '41966',
    verification_digit: '4',
    cost_center: '0'
  }

  config.correoschile = {
    name: 'CorrreosChile',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/correoschile.png',
    acronym: 'cc',
    username: 'SHIPITPRODUCCION',
    password: '664acc8a1e686da53534e42336985213',
    code: '531111'
  }

  config.correoschile = {
    name: 'CorrreosChile',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/correoschile.png',
    acronym: 'cc',
    username: 'SHIPITPRODUCCION',
    password: '664acc8a1e686da53534e42336985213',
    code: '531111'
  }

  config.dhl = {
    name: 'DHL',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/dhl.png',
    acronym: 'dhl',
    base_url: '',
    api_key: ''
  }

  config.bluexpress = {
    name: 'Bluexpress',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/bluexpress.png',
    acronym: 'bluexpress'
  }

  config.shippify = {
    name: 'Shippify',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/shippify.png',
    acronym: 'shippify'
  }

  config.moova = {
    name: 'Moova',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/moova.png',
    acronym: 'moova'
  }

  config.muvsmart = {
    name: 'Muvsmart',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/muvsmart.png',
    acronym: 'muvsmart'
  }

  config.muvsmart_mx = {
    name: 'Muvsmart_Mx',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/muvsmart.png',
    acronym: 'muvsmart_mx'
  }

  config.chileparcels = {
    name: 'Chileparcels',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/chileparcels.png',
    acronym: 'chileparcels',
    token_tracking: 'UCsydUxzbnpHanJXbFEyM0hwcGtuSWtpRk1xQ2tuS2ZzUzBielUvUUdkOUFnWFluWVFyaVE5am1qQXNhcUFzMVVsdGRnMWJ5d3pScXkrb3hXOVd3akE9PQ==',
    token_label: 'UCsydUxzbnpHanJXbFEyM0hwcGtuSWtpRk1xQ2tuS2ZzUzBielUvUUdkK2ZMZGlzWjV5bTFHNGxmaW00cVNFZTJqMWtPcDVzblhTN2Vad1I2bCt6ckE9PQ==',
  }

  config.chazki = {
    name: 'Chazki',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/chazki.png',
    acronym: 'chazki'
  }

  config.spread = {
    name: 'Spread',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/spread.png',
    acronym: 'spread'
  }

  config.integration = {
    client_id: '',
    client_secret: '',
    authorization_token: '',
    access_token: '',
    automatic_delivery: false,
    version: 1,
    checkout: {
      show_days: true,
      show_rate: true,
      custom_delivery_promise: { active: false,
                                 type: 1,
                                 custom_message: 'Despacho a domicilio',
                                 min_days_plus: 0,
                                 max_days_plus: 0 },
      rates: {
        when_show_shipit_rate: 'with_no_rates',
        courier: 'Shipit',
        logo: 'https://shipit-platform.s3-us-west-2.amazonaws.com/logo_shipit.png',
        zones: {
          13 => 5_824,
          1 => 12_674,
          2 => 10_799,
          3 => 12_674,
          4 => 6_959,
          5 => 6_158,
          6 => 6_263,
          7 => 6_670,
          8 => 6_670,
          9 => 7_192,
          10 => 7_967,
          11 => 13_398,
          12 => 13_268,
          14 => 7_854,
          15 => 12_674,
          16 => 6_421
        }
      }
    }
  }

  config.motopartner = {
    name: 'Motopartner',
    icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/motopartner.png',
    acronym: 'motopartner',
    base_url: 'https://admin.fusiongo.cl/',
    api_key: 'pdh43csj0kqnkhe0o5k8na'
  }

  config.printnode_token = 'a95f3151806b6ca35477e6507b4c8349f7acf674'
  config.rabbitmq = {
    protocol: 'amqp',
    host: 'localhost',
    port: 5672,
    heartbeat: 20,
    daemonize: false,
    workers: 1,
    log: 'log/workers.log',
    pid_path: '/tmp/pids/workers.pid',
    prefetch: 1,
    threads: 1,
    user: 'guest',
    password: 'guest'
  }
  config.hubspot_api_key = 'a526afec-aa62-45b1-a023-151be0987889'
  config.zendesk = {
    url: 'https://shipitcl.zendesk.com/api/v2',
    email: 'carolina@shipit.cl',
    token: ENV['ZENDESK_TOKEN'],
    password: 'Alliturf1'
  }

  config.zendesk_bot_data = {
    assignee_id: 6734195687,
    submitter_id: 6734195687,
    group_id: 360009769353
  }

  config.database = {
    host: ENV['DEVELOPMENT_CLIENT_DATABASE_HOST'],
    database_name: ENV['DEVELOPMENT_CLIENT_DATABASE_NAME'],
    username: ENV['DEVELOPMENT_CLIENT_DATABASE_USERNAME'],
    password: ENV['DEVELOPMENT_CLIENT_DATABASE_PASSWORD'],
    pool: 50
  }

  config.whatsapp = {
    instance: 'L1573577668939c',
    api_token: '5d93c565bfbb33001254e08fRbI142sGK'
  }

  config.boxify_endpoint = 'http://localhost:3002/'
  config.shopify_app_url = 'https://staging.shopify.shipit.cl/emergency_rates'
  config.prices_url = 'http://localhost:9001/v'
  config.order_endpoint = 'http://localhost:8000/v'
  config.duemint = {
    api_token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjb21wYW55SWQiOiIxNjEiLCJ1bmlxdWUiOiJiMGIyMDIwNGNjYjVmZDMwM2NmMDZmOTE1MzFkNWMyMjc3MTBlN2M2In0.rQ1jYjnf2cqxQ4S-Bptejyuwo2tyFdYJb8F_0ONhLX8'
  }
  config.redis_url = ''
  config.redis_host = '127.0.0.1'
  config.wicked_pdf_conf = {}

  config.mixpanel_token = ENV['MIXPANEL_TOKEN']
  config.mixpanel_enable = ENV['ENABLE_MIXPANEL_TRACKER']
  config.elastic_api_url = 'http://localhost:3006/v'
  config.pick_and_pack_url = 'http://localhost:3001/api/'

  config.timezone_offset = ENV.fetch('TIMEZONE_OFFSET') { '-0300' }

  config.internal = {
    url: ENV.fetch('INTERNAL_URL') {'http://localhost:5500/v'},
    available_set_price: ActiveRecord::Type::Boolean.new.cast(
      ENV.fetch('AVAILABLE_SET_PRICE', true)
    )
  }
end
