Sneakers.configure amqp: "#{Rails.configuration.rabbitmq[:protocol]}://#{Rails.configuration.rabbitmq[:user]}:#{Rails.configuration.rabbitmq[:password]}@#{Rails.configuration.rabbitmq[:host]}:#{Rails.configuration.rabbitmq[:port]}",
                   heartbeat: Rails.configuration.rabbitmq[:heartbeat],
                   daemonize: Rails.configuration.rabbitmq[:daemonize],
                   workers: Rails.configuration.rabbitmq[:workers],
                   log: Rails.configuration.rabbitmq[:log],
                   timeout_job_after: 20,
                   start_worker_delay: 0.5,
                   prefetch: Rails.configuration.rabbitmq[:prefetch],
                   threads: Rails.configuration.rabbitmq[:threads],
                   env: nil,
                   durable: true,
                   ack: true
Sneakers.logger.level = Logger::INFO
