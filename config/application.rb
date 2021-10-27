require_relative 'boot'

require 'rails/all'
require 'csv'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
require 'mongoid'
require 'net/http'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load

module ShipitCore
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.encoding = 'utf-8'
    config.time_zone = 'Santiago'
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_types = [:datetime]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.default_locale = :es
    config.i18n.available_locales = [:es, :en]
    # config.active_record.raise_in_transactional_callbacks = true

    config.autoload_paths << "#{Rails.root}/lib"
    config.autoload_paths += Dir[Rails.root.join("app", "models", "{*/}")]
    config.autoload_paths += Dir[Rails.root.join("app", "workers", "{*/}")]

    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components')


    Mongoid.load!(Rails.root.join('config/mongoid.yml'))

    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: true,
        request_specs: true
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end

    config.generators do |g|
      g.orm              :active_record
    end

    config.active_job.queue_adapter = :sidekiq
    config.middleware.use Rack::Attack

    config.countries = config_for(:countries)
  end
end
