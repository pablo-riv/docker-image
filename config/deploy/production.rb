set :ssh_options, user: 'deploy', forward_agent: true, auth_methods: %w[publickey]

set :stage, :production
set :rails_env, :production
set :user, 'deploy'
set :puma_threads,    [1, 8]
set :puma_workers,    8

set :pty,             true
set :use_sudo,        false
set :branch,          'master'
set :tmp_dir,         '/home/deploy/tmp'
set :deploy_via,      :remote_cache
set :bundle_gemfile,  'Gemfile'
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}_puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true # Change to true if using ActiveRecord
set :bundle_without, %w[test].join(' ')

server '34.209.122.160', user: 'deploy', roles: %w{web app db}
