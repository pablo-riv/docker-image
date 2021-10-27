namespace :whatsapp do
  desc 'Add whatsapp template to all companies'
  task migrate: :environment do
    Company.all.each do |company|
      %w[in_preparation in_route delivered failed by_retired].each_with_index do |_state, index|
        company.whatsapp_notifications.create(state: index)
      end
    end
  end
end
