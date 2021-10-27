namespace :tools do
  desc 'Clear cache'
  task clear_cache: :environment do
    Rails.cache.clear
  end
end
