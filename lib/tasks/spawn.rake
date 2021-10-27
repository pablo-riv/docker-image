namespace :spawn do
  desc 'Run groups sneakers'
  task run: :environment do
    require 'sneakers/spawner'
    Sneakers::Spawner.spawn
  end
end
