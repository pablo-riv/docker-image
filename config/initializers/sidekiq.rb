@url_sidekiq = 'redis://clientes-prod.nmc4qr.ng.0001.usw2.cache.amazonaws.com:6379/5'
Sidekiq.configure_server do |config|
  config.redis = { url: @url_sidekiq }
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::RetryJobs, max_retries: 3
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: @url_sidekiq }
end

Sidekiq.default_worker_options = { retry: 3 }
