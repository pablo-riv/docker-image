$redis =
  if Rails.env.production?
    url = "redis://#{Rails.configuration.cache_store[1][:host]}:6379/5"
    Redis::Namespace.new("shipit-core:#{Rails.env}", redis: Redis.new(url: url))
  else
    Redis::Namespace.new("shipit-core:#{Rails.env}", redis: Redis.new)
  end
