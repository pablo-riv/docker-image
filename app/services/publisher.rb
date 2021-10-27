class Publisher
  # In order to publish message we need a exchange name.
  # Note that RabbitMQ does not care about the payload -
  # we will be using JSON-encoded strings
  def self.publish(exchange, message = {})
    x = channel.fanout("core.#{exchange}")
    x.publish(message.to_json)
  end

  def self.channel
    @channel ||= connection.create_channel
  end

  def self.purge(queue)
    x = channel.queue(queue, auto_delete: false, durable: true)
    x.purge
    true
  rescue StandardError => _e
    false
  end

  # We are using default settings here
  # The `Bunny.new(...)` is a place to
  # put any specific RabbitMQ settings
  # like host or port
  def self.connection
    @connection ||= Bunny.new("#{Rails.configuration.rabbitmq[:protocol]}://#{Rails.configuration.rabbitmq[:user]}:#{Rails.configuration.rabbitmq[:password]}@#{Rails.configuration.rabbitmq[:host]}:#{Rails.configuration.rabbitmq[:port]}")
    @connection.start
  end
end
