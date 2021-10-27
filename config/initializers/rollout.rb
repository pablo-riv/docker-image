require 'redis'

$redis_rollout =
  if Rails.env.production?
    url = 'redis://shipit.nmc4qr.0001.usw2.cache.amazonaws.com:6379/5'
    Redis::Namespace.new("shipit-core-rollout:#{Rails.env}", redis: Redis.new(url: url))
  else
    Redis::Namespace.new("shipit-core-rollout:#{Rails.env}", redis: Redis.new)
  end


$rollout = Rollout.new($redis_rollout)
