# config valid only for current version of Capistrano
#lock '3.6.1'

set :application, 'clientes'
set :repo_url, 'git@github.com:shipit-team/clientes.git'
set :deploy_to, '/home/deploy/www/clientes'
set :bundle_flags, '--no-deployment --quiet'
set :rake, 'bundle exec rake'
set :console_user, nil
set :console_role, :app
set :keep_releases, 5
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
append :linked_dirs, 'log'

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
      execute "mkdir #{shared_path}/tmp/nginx -p"
      execute "mkdir #{shared_path}/tmp/nginx/cache -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/#{fetch(:branch)}`
        puts "WARNING: HEAD is not the same as origin/#{fetch(:branch)}"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Check env vairables'
  task :check_dotenv do
    on roles(:app) do
      within "#{current_path}" do
        invoke 'dotenv:read'
        invoke 'dotenv:setup'
      end
    end
  end

  desc 'Run Sneakers'
  task :sneaker_run do
    on roles(:app) do
      within "#{current_path}" do
        with RAILS_ENV: fetch(:stage) do
          puts "KILLING SNEAKERS PROCESS"
          execute "cd #{releases_path}/$(echo $(ls #{releases_path}/ -r | head -n1))"
          execute "ps aux | grep '/vendor/bundle/ruby/2.3.0/bin/rake sneakers:run' | grep -v 'grep' | awk '{print $2}' | xargs kill -9"
          puts "RUNNING SNEAKERS PROCESS"
          execute :rake, 'sneakers:run'
          execute :rake, 'spawn:run'
        end
      end
    end
  end

  desc 'Run Sidekiq'
  task :sidekiq_run do
    on roles(:app) do
      within "#{current_path}" do
        with RAILS_ENV: fetch(:stage) do
          puts "KILLING SIDEKIQS PROCESS"
          execute "ps aux | grep 'sidekiq 4.0.2 clientes' | grep -v 'grep' | awk '{print $2}' | xargs kill -9"
          puts "RUNNING SIDEKIQS PROCESS"
          execute :bundle, "exec sidekiq -e #{fetch(:stage)} -L log/sidekiq.log -C config/sidekiq.yml -d"
        end
      end
    end
  end

  desc "Bundle gems"
  task :bundle_install do
    puts "BUNDLE INSTALL...."
    run "cd #{current_path} && bundle install"
    execute :rake, 'courier:setup'
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  desc 'Copy svg'
  task :copy_svg do
    puts "COPY SVG INTO PUBLIC/ASSETS"
    on roles(:app) do
      execute "cd #{current_path} && cp app/assets/images/svg/*.svg #{current_path}/public/assets/"
      execute "cd #{current_path} && cp app/assets/svg/* #{current_path}/public/assets/"
      execute "cd #{current_path} && mkdir -p public/xlsx"
    end
  end

  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :check_dotenv
  after  :finishing,    :copy_svg
  after  :finishing,    :cleanup
  after  :finishing,    :restart
  after  :finishing,    :sneaker_run
  after  :finishing,    :sidekiq_run
end
