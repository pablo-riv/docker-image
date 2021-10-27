Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  config.enable_dependency_loading = true

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.action_controller.asset_host = 'clientes.shipit.cl'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  config.cache_store = :redis_store, {
    host: ENV.fetch('SHIPIT_CLIENTES_REDIS_CACHE_URL') { 'clientes-prod.nmc4qr.ng.0001.usw2.cache.amazonaws.com' },
    port: 6379,
    db: 0,
    namespace: 'api'
  }, {
    expires_in: 90.minutes
  }

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "shipit-core_#{Rails.env}"
  config.active_record.dump_schema_after_migration = false
  config.action_mailer.default_url_options = { host: 'clientes.shipit.cl' }

  config.default_url_options = { host: 'clientes.shipit.cl' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.bootic = {
    client_id: '0526ade27f99a3b1bf21bb06ae631d5c',
    client_secret: '03bf60bb2a65d6f0cb626da986e8947e'
  }

  ActionMailer::Base.smtp_settings = {
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    domain: 'shipit.cl',
    address: 'email-smtp.us-west-2.amazonaws.com',
    port: 587,
    authentication: :login,
    enable_starttls_auto: true
  }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
  config.paperclip_defaults = {
    storage: :s3,
    s3_region: ENV['AWS_REGION'],
    s3_credentials: {
      bucket: 'shipit-platform',
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    }
  }

  config.slack_token = ENV['SHIPIT_SLACK_TOKEN']
  config.zendesk_token = ENV['SHIPIT_ZENDESK_TOKEN']

  config.opit_endpoint = 'http://opit.shipit.cl'
  config.fulfillment_endpoint = 'http://fulfillment.shipit.cl/api/'
  config.statuses_endpoint = 'http://courierstatus.shipit.cl/v/'
  config.action_cable.url = 'wss://clientes.shipit.cl/cable'
  config.action_cable.allowed_request_origins = ["http://clientes.shipit.cl", "https://clientes.shipit.cl"]
  config.rollbar_access_token = ENV['SHIPIT_ROLLBAR_TOKEN']

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
    protocol: 'amqps',
    host: ENV.fetch('SHIPIT_RABBIT_HOST') { 'b-fe58d27e-1e6d-46c3-ac7a-b6524620f898.mq.us-west-2.amazonaws.com' },
    port: ENV.fetch('SHIPIT_RABBIT_PORT') { 5671 },
    heartbeat: 2,
    daemonize: true,
    workers: ENV.fetch('SHIPIT_RABBIT_WORKERS').to_i { 2 },
    log: 'log/workers.log',
    pid_path: '/tmp/pids/workers.pid',
    prefetch: ENV.fetch('SHIPIT_RABBIT_PREFETCH').to_i { 1 },
    threads: ENV.fetch('SHIPIT_RABBIT_THREADS').to_i { 1 },
    user: ENV.fetch('SHIPIT_RABBIT_USERNAME') { 'guest' },
    password: ENV.fetch('SHIPIT_RABBIT_PASSWORD') { 'guest' }
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
    host: ENV['SHIPIT_CORE_HOST'],
    database_name: ENV['SHIPIT_CORE_DATABASE'],
    username: ENV['SHIPIT_CORE_USERNAME'],
    password: ENV['SHIPIT_CORE_PASSWORD'],
    pool: ENV['SHIPIT_CORE_POOL']
  }

  config.whatsapp = {
    instance: 'L1573577668939c',
    api_token: '5d93c565bfbb33001254e08fRbI142sGK'
  }
  config.boxify_endpoint = 'https://boxify.shipit.cl/'
  config.shopify_app_url = 'https://shopify.shipit.cl/emergency_rates'
  config.prices_url = 'https://prices.shipit.cl/v'
  config.order_endpoint = 'https://orders.shipit.cl/v'
  config.elastic_api_url = 'https://elastic.shipit.cl/v' # Pending on release

  config.duemint = {
    api_token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjb21wYW55SWQiOiIxNjEiLCJ1bmlxdWUiOiJiMGIyMDIwNGNjYjVmZDMwM2NmMDZmOTE1MzFkNWMyMjc3MTBlN2M2In0.rQ1jYjnf2cqxQ4S-Bptejyuwo2tyFdYJb8F_0ONhLX8'
  }
  config.redis_url = 'redis://app.nmc4qr.ng.0001.usw2.cache.amazonaws.com:6379'
  config.redis_host = ''
  config.wicked_pdf_conf = {}

  config.mixpanel_token = ENV['SHIPIT_MIXPANEL_TOKEN']
  config.mixpanel_enable = true
  config.pick_and_pack_url = "#{ENV['PP_ADDRESS']}/api/"
  config.timezone_offset = ENV.fetch('TIMEZONE_OFFSET') { '-0300' }

  config.internal = {
    url: ENV.fetch('INTERNAL_URL') {'https://internal.shipit.cl/v'},
    available_set_price: ActiveRecord::Type::Boolean.new.cast(
      ENV.fetch('AVAILABLE_SET_PRICE', 'true')
    )
  }
end
