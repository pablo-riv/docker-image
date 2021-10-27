Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Middlewares tokens
  config.slack_token = 'xoxb-441973426945-634769395686-DT6zRzM3ns4Xcr3wkxzTnJZR'
  config.zendesk_token = '2a6b30db-a1f0-466b-a61a-91bc8c50a2e1'

  config.rollbar_access_token = 'f102ef0db30b4f2798e63d7f5412bf41'
  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  config.bootic = {
    client_id: '0526ade27f99a3b1bf21bb06ae631d5c',
    client_secret: '03bf60bb2a65d6f0cb626da986e8947e'
  }
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
    api_key: '',
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
    heartbeat: 1,
    daemonize: false,
    workers: 1,
    log: 'log/workers.log',
    pid_path: '/tmp/pids/workers.pid',
    prefetch: 1,
    threads: 1,
    user: 'guest',
    password: 'guest'
  }
  config.hubspot_api_key = '407906b5-241e-4916-bfdd-a6208f2fddb7'
  config.zendesk = {
    url: 'https://shipitcl.zendesk.com/api/v2',
    email: 'carolina@shipit.cl',
    token: 'yYx7m3eKFQDygDkJdu5DvNWdqGSHjDsfpHmaI3Ne'
  }

  config.database = {
    host: ENV['TEST_CLIENT_DATABASE_HOST'],
    database_name: ENV['TEST_CLIENT_DATABASE_NAME'],
    username: ENV['TEST_CLIENT_DATABASE_USERNAME'],
    password: ENV['TEST_CLIENT_DATABASE_PASSWORD'],
    pool: 50
  }

  config.whatsapp = {
    instance: 'L1573577668939c',
    api_token: '5d93c565bfbb33001254e08fRbI142sGK'
  }
  config.boxify_endpoint = 'http://localhost:3002/'

  config.prices_url = 'http://localhost:9001/v'
  config.order_endpoint = 'http://localhost:8000/v'
  config.fulfillment_endpoint = 'http://localhost:4000/api/'
  config.elastic_api_url = 'http://localhost:3006/v'

  config.whatsapp = {
    instance: 'L1573577668939c',
    api_token: '5d93c565bfbb33001254e08fRbI142sGK'
  }

  config.duemint = {
    api_token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjb21wYW55SWQiOiIxNjEiLCJ1bmlxdWUiOiJiMGIyMDIwNGNjYjVmZDMwM2NmMDZmOTE1MzFkNWMyMjc3MTBlN2M2In0.rQ1jYjnf2cqxQ4S-Bptejyuwo2tyFdYJb8F_0ONhLX8'
  }
  config.redis_url = ''
  config.redis_host = '127.0.0.1'

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
  config.wicked_pdf_conf = {}
  config.pick_and_pack_url = 'http://localhost:3001/api/'
  config.timezone_offset = ENV.fetch('TIMEZONE_OFFSET') { '-0300' }

  config.internal = {
    url: ENV.fetch('INTERNAL_URL') {'http://localhost:5500/v'},
    available_set_price: ActiveRecord::Type::Boolean.new.cast(
      ENV.fetch('AVAILABLE_SET_PRICE', true)
    )
  }
end
