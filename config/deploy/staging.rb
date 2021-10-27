set :ssh_options, {
  user: 'deploy',
  forward_agent: true,
  auth_methods: %w(publickey),
}

set :stage, :staging
set :user, 'deploy'
set :puma_threads,    [1, 1]
set :puma_workers,    1

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :branch,          'staging'
set :tmp_dir,         '/home/deploy/tmp'
set :deploy_via,      :remote_cache
set :bundle_gemfile, 'Gemfile'
set :rvm_ruby_string, '2.3.7'
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}_puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, false  # Change to true if using ActiveRecord
set :bundle_without, %w{test}.join(' ')
set :env_file, ".env.staging"

set :default_env, {
  'RABBITMQ_HOST' => '34.223.254.64',
  'OPIT_URL' => 'http://staging.opit.shipit.cl',
  'STAGING_CLIENT_DATABASE_NAME' => 'staging_shipit_core',
  'SNEAKERS_HEARTBEAT' => 2,
  'SNEAKERS_DAEMONIZE' => true,
  'SNEAKERS_WORKERS' => 1,
  'SNEAKERS_LOG' => "#{current_path}/log/workers.log",
  'SNEAKERS_PID_PATH' => "#{shared_path}/tmp/pids/workers.pid",
  'SNEAKERS_PREFETCH' => 1,
  'SNEAKERS_THREADS' => 1,
  'STAGING_CLIENT_DATABASE_HOST' => '127.0.0.1',
  'DEVISE_SECRET_KEY' => '401e9dbe15e64c248de9f22cff5f726c30ecbab7c5c453157fb53153ad26ff92e95e017422cb4f2fe08310eeaffdf40ec5cee9a1789c9d0fb550689bcd6c51bf',
  'RAILS_SERVE_STATIC_FILES' => true,
  'BOOTIC_CLIENT_ID' => '0526ade27f99a3b1bf21bb06ae631d5c',
  'BOOTIC_CLIENT_SECRET' => '03bf60bb2a65d6f0cb626da986e8947e',
  'MIXPANEL_TOKEN' => 'de6c891c695a2259910fa0e854276f92',
  'ENABLE_MIXPANEL_TRACKER' => false,
  'AWS_ACCESS_KEY' => 'AKIAJVE7T5EVTFLRXAEQ',
  'AWS_SECRET_ACCESS_KEY' => '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',
  'AWS_REGION' => 'us-west-2'
}


server 'staging.clientes.shipit.cl', user: 'deploy', roles: %w{web app db}
